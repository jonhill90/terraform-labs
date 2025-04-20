# Shared Memory Framework Server API

This document describes the REST API endpoints provided by the Shared Memory Framework Server.

## Base URL

All endpoints are relative to the base URL: `http://localhost:5678`

## API Endpoints

### Health Check

Verify the server is running and check its configuration status.

**Request**:
```
GET /health
```

**Response**:
```json
{
  "status": "healthy",
  "configured": true,
  "version": "0.1.0",
  "name": "Shared Memory Framework Server"
}
```

### Configuration

Get or update server configuration.

**Request (GET)**:
```
GET /config
```

**Response**:
```json
{
  "vault_configured": true,
  "api_version": "0.1.0"
}
```

**Request (POST)**:
```
POST /config
Content-Type: application/json

{
  "vault_path": "/path/to/obsidian/vault"
}
```

**Response**:
```json
{
  "status": "Configuration updated successfully"
}
```

### Search Notes

Search for notes matching a query.

**Request**:
```
GET /search?query=terraform
```

**Response**:
```json
[
  "AI/Memory/Contexts/Shared/TerraformBestPractices.md",
  "AI/Memory/Conversations/Claude/20250419-TerraformRefactoring.md"
]
```

### Read Notes

Read one or more notes by path.

**Request**:
```
GET /read?path=AI/Memory/Contexts/Shared/TerraformBestPractices.md
```

To read multiple notes:
```
GET /read?path=AI/Memory/Contexts/Shared/TerraformBestPractices.md&path=AI/Memory/Contexts/Shared/AzureNetworking.md
```

**Response**:
```json
{
  "AI/Memory/Contexts/Shared/TerraformBestPractices.md": "# Terraform Best Practices\n\n## Module Structure\n..."
}
```

### Write Note

Write content to a note.

**Request**:
```
POST /write
Content-Type: application/json

{
  "path": "AI/Memory/Contexts/Test/NewNote.md",
  "content": "# Test Note\n\nThis is a test note."
}
```

**Response**:
```json
{
  "status": "success",
  "path": "AI/Memory/Contexts/Test/NewNote.md"
}
```

### Metadata

Get metadata about the vault structure.

**Request**:
```
GET /metadata
```

**Response**:
```json
{
  "vault_configured": true,
  "stats": {
    "contexts": 15,
    "conversations": 27,
    "system_prompts": 8,
    "projects": 5
  }
}
```

## Error Responses

All endpoints return appropriate HTTP status codes:

- 200: Success
- 400: Bad request (missing parameters or invalid input)
- 500: Server error (configuration issues or internal errors)

Error responses include a JSON body with an "error" field describing the issue:

```json
{
  "error": "Server not configured. Set vault_path first."
}
```