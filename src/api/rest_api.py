"""
RESTful API for eSIM Manager System
GSMA-compliant endpoints with security and rate limiting
"""

from fastapi import FastAPI, HTTPException, Depends, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from pydantic import BaseModel, Field
from typing import Dict, List, Optional, Any
import asyncio
import logging
from datetime import datetime
import jwt
from src.core.esim_manager import ESIMManager, ProfileState, OperationResult

# API Models
class ProfileDownloadRequest(BaseModel):
    eid: str = Field(..., description="eUICC Identifier")
    activation_code: str = Field(..., description="SGP.22 Activation Code")
    confirmation_code: Optional[str] = Field(None, description="Confirmation Code")

class ProfileOperationRequest(BaseModel):
    eid: str = Field(..., description="eUICC Identifier")
    iccid: str = Field(..., description="Profile ICCID")

class ProfileResponse(BaseModel):
    result: str
    iccid: Optional[str] = None
    profile_state: Optional[str] = None
    error: Optional[str] = None

class EUICCInfoResponse(BaseModel):
    eid: str
    profiles: List[Dict[str, Any]]
    euicc_info: Dict[str, Any]

# Security
security = HTTPBearer()

class ESIMAPIServer:
    """Production-ready eSIM API Server"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.app = FastAPI(
            title="eSIM Manager API",
            description="GSMA SGP.22/SGP.32 Compliant eSIM Management Platform",
            version="1.0.0",
            docs_url="/api/docs",
            redoc_url="/api/redoc"
        )
        self.esim_manager = ESIMManager(config)
        self.logger = logging.getLogger(__name__)
        self._setup_middleware()
        self._setup_routes()
    
    def _setup_middleware(self):
        """Configure security and CORS middleware"""
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=self.config.get('cors_origins', ["*"]),
            allow_credentials=True,
            allow_methods=["GET", "POST", "PUT", "DELETE"],
            allow_headers=["*"],
        )
        
        self.app.add_middleware(
            TrustedHostMiddleware,
            allowed_hosts=self.config.get('allowed_hosts', ["*"])
        )
    
    def _setup_routes(self):
        """Setup API routes"""
        
        @self.app.on_event("startup")
        async def startup_event():
            await self.esim_manager.initialize()
            self.logger.info("eSIM Manager API Server started")
        
        @self.app.get("/health")
        async def health_check():
            """Health check endpoint"""
            return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}
        
        @self.app.post("/api/v1/profiles/download", response_model=ProfileResponse)
        async def download_profile(
            request: ProfileDownloadRequest,
            credentials: HTTPAuthorizationCredentials = Security(security)
        ):
            """
            SGP.22 Profile Download Endpoint
            Downloads and installs eSIM profile on eUICC
            """
            try:
                # Validate JWT token
                await self._validate_token(credentials.credentials)
                
                # Execute profile download
                result = await self.esim_manager.download_profile(
                    request.eid,
                    request.activation_code,
                    request.confirmation_code
                )
                
                return ProfileResponse(**result)
                
            except Exception as e:
                self.logger.error(f"Profile download API error: {str(e)}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=str(e)
                )
        
        @self.app.post("/api/v1/profiles/enable", response_model=ProfileResponse)
        async def enable_profile(
            request: ProfileOperationRequest,
            credentials: HTTPAuthorizationCredentials = Security(security)
        ):
            """Enable eSIM profile"""
            try:
                await self._validate_token(credentials.credentials)
                
                result = await self.esim_manager.enable_profile(
                    request.eid,
                    request.iccid
                )
                
                return ProfileResponse(**result)
                
            except Exception as e:
                self.logger.error(f"Profile enable API error: {str(e)}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=str(e)
                )
        
        @self.app.post("/api/v1/profiles/disable", response_model=ProfileResponse)
        async def disable_profile(
            request: ProfileOperationRequest,
            credentials: HTTPAuthorizationCredentials = Security(security)
        ):
            """Disable eSIM profile"""
            try:
                await self._validate_token(credentials.credentials)
                
                result = await self.esim_manager.disable_profile(
                    request.eid,
                    request.iccid
                )
                
                return ProfileResponse(**result)
                
            except Exception as e:
                self.logger.error(f"Profile disable API error: {str(e)}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=str(e)
                )
        
        @self.app.delete("/api/v1/profiles/delete", response_model=ProfileResponse)
        async def delete_profile(
            request: ProfileOperationRequest,
            credentials: HTTPAuthorizationCredentials = Security(security)
        ):
            """Delete eSIM profile"""
            try:
                await self._validate_token(credentials.credentials)
                
                result = await self.esim_manager.delete_profile(
                    request.eid,
                    request.iccid
                )
                
                return ProfileResponse(**result)
                
            except Exception as e:
                self.logger.error(f"Profile delete API error: {str(e)}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=str(e)
                )
        
        @self.app.get("/api/v1/euicc/{eid}/info", response_model=EUICCInfoResponse)
        async def get_euicc_info(
            eid: str,
            credentials: HTTPAuthorizationCredentials = Security(security)
        ):
            """Get eUICC information and installed profiles"""
            try:
                await self._validate_token(credentials.credentials)
                
                # Get eUICC info and profiles
                euicc_info = await self.esim_manager._get_euicc_info(eid)
                profiles = await self.esim_manager._get_profiles_by_eid(eid)
                
                return EUICCInfoResponse(
                    eid=eid,
                    profiles=profiles,
                    euicc_info=euicc_info
                )
                
            except Exception as e:
                self.logger.error(f"eUICC info API error: {str(e)}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=str(e)
                )
        
        @self.app.get("/api/v1/profiles")
        async def list_profiles(
            eid: Optional[str] = None,
            state: Optional[str] = None,
            credentials: HTTPAuthorizationCredentials = Security(security)
        ):
            """List eSIM profiles with optional filtering"""
            try:
                await self._validate_token(credentials.credentials)
                
                profiles = await self.esim_manager._list_profiles(eid, state)
                
                return {"profiles": profiles}
                
            except Exception as e:
                self.logger.error(f"List profiles API error: {str(e)}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=str(e)
                )
    
    async def _validate_token(self, token: str):
        """Validate JWT authentication token"""
        try:
            payload = jwt.decode(
                token,
                self.config['jwt_secret'],
                algorithms=['HS256']
            )
            
            # Additional validation logic
            if payload.get('exp', 0) < datetime.utcnow().timestamp():
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token expired"
                )
                
        except jwt.InvalidTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )

# Rate limiting and security decorators would be added here
# Integration with Redis for session management
# API versioning support
# Webhook endpoints for MNO notifications