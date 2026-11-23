from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field

class HealthStatusEnum(str, Enum):
    UP = "UP"
    DOWN = "DOWN"
    DEGRADED = "DEGRADED"

class HealthStatus(BaseModel):
    status: HealthStatusEnum
    timestamp: datetime
    serviceName: Optional[str] = None
    version: Optional[str] = None

class PingResponse(BaseModel):
    echo: str
    serverTimeMillis: int

class ErrorDto(BaseModel):
    code: str
    description: str
    attributes: Optional[Dict[str, str]] = None

class ErrorResponse(BaseModel):
    data: Optional[Any] = None
    errors: List[ErrorDto] = Field(default_factory=list)
