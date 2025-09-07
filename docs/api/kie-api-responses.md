# KIE API Response Samples

This document contains sample responses from the KIE API to help developers understand the expected response formats and handle API changes appropriately.

## Table of Contents

- [Generate Music API](#generate-music-api)
- [Get Task Status API](#get-task-status-api)
- [Error Responses](#error-responses)

## Generate Music API

### Endpoint
`POST /api/v1/generate`

### Success Response
```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000"
  }
}
```

## Get Task Status API

### Endpoint
`GET /api/v1/generate/record-info?taskId={taskId}`

### Status: Pending
Initial state when a task is queued but not yet started.

```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "pending",
    "createdAt": "2025-01-07T10:00:00Z"
  }
}
```

### Status: Processing
Task is actively being processed.

```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "processing",
    "progress": 45,
    "createdAt": "2025-01-07T10:00:00Z",
    "startedAt": "2025-01-07T10:00:30Z"
  }
}
```

### Status: Completed
Task has been successfully completed.

```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "completed",
    "output": {
      "audio_url": "https://api.kie.ai/downloads/audio/550e8400-e29b-41d4-a716-446655440000.mp3",
      "duration": 180,
      "format": "mp3",
      "bitrate": "320kbps"
    },
    "createdAt": "2025-01-07T10:00:00Z",
    "startedAt": "2025-01-07T10:00:30Z",
    "completedAt": "2025-01-07T10:03:00Z"
  }
}
```

### Status: Success (Alternative)
Some API versions may return "success" instead of "completed".

```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "SUCCESS",
    "output": {
      "audio_url": "https://api.kie.ai/downloads/audio/550e8400-e29b-41d4-a716-446655440000.mp3",
      "duration": 180
    },
    "createdAt": "2025-01-07T10:00:00Z",
    "completedAt": "2025-01-07T10:03:00Z"
  }
}
```

### Status: Failed
Task failed during processing.

```json
{
  "code": 200,
  "msg": "Success",
  "data": {
    "taskId": "550e8400-e29b-41d4-a716-446655440000",
    "status": "failed",
    "error": "Generation failed: Insufficient credits",
    "errorCode": "INSUFFICIENT_CREDITS",
    "createdAt": "2025-01-07T10:00:00Z",
    "failedAt": "2025-01-07T10:01:00Z"
  }
}
```

## Error Responses

### Authentication Error
```json
{
  "code": 401,
  "msg": "Authentication failed",
  "error": "Invalid API key"
}
```

### Rate Limit Error
```json
{
  "code": 429,
  "msg": "Rate limit exceeded",
  "error": "Too many requests. Please wait before making more requests.",
  "retryAfter": 60
}
```

### Not Found Error
```json
{
  "code": 404,
  "msg": "Not found",
  "error": "Task not found with ID: 550e8400-e29b-41d4-a716-446655440000"
}
```

### Server Error
```json
{
  "code": 500,
  "msg": "Internal server error",
  "error": "An unexpected error occurred. Please try again later."
}
```

## Status Values

The following status values have been observed:

- **pending** / **PENDING** / **Pending**: Task is queued
- **processing** / **PROCESSING** / **Processing**: Task is being processed
- **completed** / **COMPLETED** / **Completed**: Task completed successfully
- **success** / **SUCCESS** / **Success**: Alternative success status
- **failed** / **FAILED** / **Failed**: Task failed

Note: The API may return status values in different cases (lowercase, uppercase, or mixed case). Our implementation normalizes these values to lowercase for consistent processing.

## Important Notes

1. **Status Case Sensitivity**: The API may return status values in various cases. Always normalize to lowercase when comparing.

2. **Field Variations**: Some fields like `taskId` may also appear as `task_id` in different API versions.

3. **Optional Fields**: Not all fields are guaranteed to be present in every response. Always check for field existence before accessing.

4. **Response Wrapping**: All successful responses are wrapped in a structure with `code`, `msg`, and `data` fields.

5. **Error Handling**: Even with HTTP 200 status, check the `code` field in the response as errors may be returned with 200 HTTP status.

## Monitoring Recommendations

1. Log all unexpected status values for early detection of API changes
2. Monitor for missing required fields (taskId, status)
3. Track status transition patterns to understand typical workflow
4. Alert on high failure rates or unusual error patterns
5. Keep samples of actual responses for reference and debugging