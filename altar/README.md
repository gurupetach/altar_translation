# YouTube Live Audio Translation App Setup Guide

## Overview

This Phoenix LiveView application provides real-time audio translation for YouTube live streams. It captures English audio from live streams and translates it to Kiswahili or Portuguese.

## Prerequisites

1. Elixir 1.14+ and Phoenix Framework
2. PostgreSQL database
3. Node.js (for assets)
4. `yt-dlp` or `youtube-dl` command-line tool
5. API keys for external services

## Required External Services

1. **Google Cloud Platform**
   - Speech-to-Text API
   - Translate API
   - Text-to-Speech API
   
2. **YouTube Data API v3** (for live stream validation)

3. **Optional: AWS Services**
   - Amazon Transcribe (alternative to Google Speech-to-Text)
   - Amazon Polly (alternative to Google Text-to-Speech)

## Installation Steps

### 1. Clone and Setup the Project

```bash
# Clone the repository
git clone <your-repo-url>
cd altar

# Install dependencies
mix deps.get

# Create and migrate database
mix ecto.setup

# Install Node.js dependencies
cd assets && npm install && cd ..
```

### 2. Install System Dependencies

```bash
# Install yt-dlp (recommended over youtube-dl)
# macOS
brew install yt-dlp

# Ubuntu/Debian
sudo apt update
sudo apt install yt-dlp

# Or using pip
pip install yt-dlp
```

### 3. Configure External Services

Create a `.env` file in the project root:

```bash
# Google Cloud credentials
export GOOGLE_APPLICATION_CREDENTIALS_JSON='{"type":"service_account",...}'
export GOOGLE_TRANSLATE_API_KEY="your-google-translate-api-key"

# YouTube API
export YOUTUBE_API_KEY="your-youtube-api-key"

# Optional: AWS credentials
export AWS_ACCESS_KEY_ID="your-aws-access-key"
export AWS_SECRET_ACCESS_KEY="your-aws-secret-key"
export AWS_REGION="us-east-1"
```

Load environment variables:

```bash
source .env
```

### 4. Start the Application

```bash
# Start Phoenix server
mix phx.server

# Or run inside IEx
iex -S mix phx.server
```

## Architecture Overview

The application follows this flow:

1. **URL Validation**: Validates YouTube URL and checks if it's a live stream
2. **Audio Extraction**: Uses yt-dlp to extract audio stream URL
3. **Audio Processing**: Captures audio chunks in real-time
4. **Speech Recognition**: Converts English speech to text
5. **Translation**: Translates text to target language
6. **Text-to-Speech**: Generates audio in target language
7. **Audio Playback**: Streams translated audio to browser

## Key Components

### 1. YouTube URL Validator
- Validates URL format
- Checks if stream is live using YouTube Data API

### 2. Audio Processor
- GenServer that manages the audio pipeline
- Handles buffering and chunk processing

### 3. Speech Recognition
- Integrates with Google Speech-to-Text API
- Processes audio chunks continuously

### 4. Translation Service
- Uses Google Translate API
- Maintains context across segments

### 5. Text-to-Speech Synthesis
- Converts translated text to speech
- Supports multiple voices for different languages

## Production Considerations

### 1. API Rate Limits
- Implement rate limiting for API calls
- Consider caching frequent translations

### 2. Error Handling
- Add robust error handling for network failures
- Implement retry logic for API calls

### 3. Scalability
- Use connection pooling for API clients
- Consider using message queues for heavy processing

### 4. Security
- Store API keys securely (use environment variables)
- Implement user authentication if needed
- Add rate limiting for user requests

### 5. Performance Optimization
- Optimize audio chunk sizes
- Implement efficient buffering strategies
- Consider using WebRTC for lower latency

## Testing

```bash
# Run tests
mix test

# Run tests with coverage
mix test --cover

# Run specific test file
mix test test/altar_web/live/translator_live_test.exs
```

## Deployment

### Using Docker

```dockerfile
# Dockerfile
FROM elixir:1.14-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git python3

# Install yt-dlp
RUN apk add --no-cache ffmpeg
RUN pip3 install yt-dlp

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy assets
COPY priv priv
COPY assets assets

# Compile assets
RUN mix assets.deploy

# Compile project
COPY lib lib
RUN mix compile

# Copy runtime config
COPY config/runtime.exs config/

# Create release
RUN mix release

# Start a new build stage
FROM alpine:3.16 AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache ffmpeg
RUN apk add --no-cache python3 py3-pip
RUN pip3 install yt-dlp

# Copy the release from build stage
COPY --from=build /app/_build/prod/rel/altar ./

ENV HOME=/app

CMD ["bin/altar", "start"]
```

### Deployment Platforms

1. **Fly.io** (recommended for Phoenix apps)
```bash
fly launch
fly deploy
```

2. **Heroku**
```bash
heroku create
heroku buildpacks:set hashnuke/elixir
heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
git push heroku main
```

3. **Google Cloud Run**
```bash
# Build and push Docker image
docker build -t gcr.io/your-project/altar .
docker push gcr.io/your-project/altar

# Deploy to Cloud Run
gcloud run deploy altar --image gcr.io/your-project/altar
```

## Troubleshooting

### Common Issues

1. **yt-dlp not found**
   - Ensure yt-dlp is installed and in PATH
   - Check installation with `which yt-dlp`

2. **API Authentication Errors**
   - Verify API keys are correct
   - Check Google Cloud service account permissions

3. **Audio Processing Issues**
   - Check audio format compatibility
   - Verify sample rates match configuration

4. **Memory Issues**
   - Monitor GenServer memory usage
   - Implement audio buffer cleanup

## Next Steps

1. Implement WebRTC for lower latency audio streaming
2. Add support for more languages
3. Implement user accounts and usage limits
4. Add audio quality selection
5. Create mobile-responsive UI
6. Add real-time waveform visualization
7. Implement offline translation caching

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

```graph TD
graph TD
    A[User Interface - Phoenix LiveView] --> B[URL Validator]
    B --> C{Is Live Stream?}
    C -->|Yes| D[Audio Stream Extractor]
    C -->|No| E[Show Error]
    
    D --> F[Audio Processor GenServer]
    F --> G[Audio Buffer]
    G --> H[Speech Recognition]
    
    H --> I[Google Speech-to-Text API]
    I --> J[English Transcript]
    
    J --> K[Translation Service]
    K --> L[Google Translate API]
    L --> M[Translated Text]
    
    M --> N[Text-to-Speech Synthesis]
    N --> O[Google TTS API]
    O --> P[Translated Audio]
    
    P --> Q[Audio Player]
    Q --> A
    
    F --> R[WebSocket Connection]
    R --> A
    
    style A fill:#f9f,stroke:#333,stroke-width:4px
    style F fill:#bbf,stroke:#333,stroke-width:4px
    style H fill:#bfb,stroke:#333,stroke-width:4px
    style K fill:#fbf,stroke:#333,stroke-width:4px
    style N fill:#ffb,stroke:#333,stroke-width:4px

```