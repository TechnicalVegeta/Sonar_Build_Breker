[![.github/workflows/action.yml](https://github.com/TechnicalVegeta/Sonar_Build_Breker/actions/workflows/action.yml/badge.svg)](https://github.com/TechnicalVegeta/Sonar_Build_Breker/actions/workflows/action.yml)
[![SonarQube Analysis](https://github.com/TechnicalVegeta/Sonar_Build_Breker/actions/workflows/sonarqube.yml/badge.svg)](https://github.com/TechnicalVegeta/Sonar_Build_Breker/actions/workflows/sonarqube.yml)

# Validating Sonar Analysis and Quality Gates   


This GitHub action is used to fail GitHub workflow in case Quality Gates failed and compatiable for all runners of all os. This GitHub action expect the following required parametes:

| Parameters   | Required | 
|--------------|----------|
| sonar_url    |   yes    |
| sonar_token  |   yes    |
| project_key  |   yes    |
| sonar_branch |   yes    |

Sample Code Example:

```
- name: Sonar Build Breaker
  uses: TechnicalVegeta/Sonar_Quality_Gate@main
  with:
    sonar_url: "https://sonarcloud.io"
    sonar_branch: "main"
    sonar_token: ${{ secrets.SONAR_TOKEN }}
    project_key: "sonar_project_key"
```
