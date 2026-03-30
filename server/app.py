"""
MediGuide AI - OpenEnv Server
============================
Server entry point for OpenEnv validation
"""

import uvicorn
from inference import app


def main():
    uvicorn.run(app, host="0.0.0.0", port=7860)


if __name__ == "__main__":
    main()
