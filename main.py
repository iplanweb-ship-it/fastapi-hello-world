from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import logging
import os

# OpenTelemetry imports
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.logging import LoggingInstrumentor

# --- Configure OpenTelemetry ---
LOGZIO_OTLP_ENDPOINT = os.getenv("LOGZIO_OTLP_ENDPOINT", "https://api.logz.io:443") 
LOGZIO_OTLP_TOKEN = os.getenv("LOGZIO_OTLP_TOKEN", "<TOKEN>")

resource = Resource(attributes={"service.name": "fastapi-hello-world"})
provider = TracerProvider(resource=resource)
trace.set_tracer_provider(provider)

otlp_exporter = OTLPSpanExporter(
    endpoint=LOGZIO_OTLP_ENDPOINT,
    headers=(("Authorization", f"Bearer {LOGZIO_OTLP_TOKEN}"),)
)
provider.add_span_processor(BatchSpanProcessor(otlp_exporter))

# --- Create FastAPI app ---
app = FastAPI()
FastAPIInstrumentor.instrument_app(app)
LoggingInstrumentor().instrument(set_logging_format=True)

logger = logging.getLogger("uvicorn.access")

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Middleware to log every request with method, path, name, and status."""
    name = request.query_params.get("name", None)
    method = request.method
    path = request.url.path

    response = await call_next(request)
    status_code = response.status_code

    logger.info(
        f"Request: method={method}, path={path}, status={status_code}, name={name}"
    )
    return response

@app.get("/")
async def read_root(name: str = None):
    """Main endpoint returning Hello message."""
    if name:
        return {"message": f"Hello {name}"}
    return {"message": "Hello World"}

@app.get("/healthz")
async def health_check():
    """Simple health check endpoint."""
    return JSONResponse(status_code=200, content={"status": "ok"})
