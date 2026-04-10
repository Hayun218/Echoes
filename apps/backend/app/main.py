from fastapi import FastAPI
from app.api.v1.routes import router

app = FastAPI(title="Echoes Backend")
app.include_router(router, prefix="/api/v1")