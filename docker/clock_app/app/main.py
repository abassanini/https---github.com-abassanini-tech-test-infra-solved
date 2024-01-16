from fastapi import FastAPI
import time

app = FastAPI()

@app.get("/clock")
async def root():
    return time.time()
