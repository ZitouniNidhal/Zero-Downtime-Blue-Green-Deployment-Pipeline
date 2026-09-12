@echo off
echo Starting Blue-Green services...
docker compose up -d
echo.
echo Services are starting. Check status with: docker compose ps
echo.
curl http://localhost/
pause