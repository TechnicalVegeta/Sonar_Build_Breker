#!/bin/bash
: '
This script runs a SonarQube Docker container, waits for it to start, logs in to SonarQube, 
creates a new project with the specified name and key, 
and then retrieves the project key of the newly created project. 
The project key is then printed to the console.
'

# Set environment variables
export SONARQUBE_USERNAME=admin
export SONARQUBE_PASSWORD=admin

# Run SonarQube Docker container
docker run -d --name sonarqube -p 9000:9000 sonarqube:latest

# Wait for SonarQube to start
sleep 60

# Login to SonarQube
curl -u $SONARQUBE_USERNAME:$SONARQUBE_PASSWORD -X POST http://localhost:9000/api/authentication/login

# Set project details
PROJECT_NAME="test_build_breaker_project"
PROJECT_KEY="test_build_breaker_key"

# Create project
curl -u $SONARQUBE_USERNAME:$SONARQUBE_PASSWORD -X POST "http://localhost:9000/api/projects/create?name=$PROJECT_NAME&project=$PROJECT_KEY"

# Get project key
PROJECT_KEY=$(curl -u $SONARQUBE_USERNAME:$SONARQUBE_PASSWORD -X GET "http://localhost:9000/api/projects/search?projects=$PROJECT_KEY" | jq -r '.components[0].key')

echo "Project key: $PROJECT_KEY"

# Generate user token for scanning
TOKEN_NAME="mytoken"
USER_TOKEN=$(curl -u $SONARQUBE_USERNAME:$SONARQUBE_PASSWORD -X POST "http://localhost:9000/api/user_tokens/generate?name=$TOKEN_NAME" | jq -r '.token')

echo "User token: $USER_TOKEN"
