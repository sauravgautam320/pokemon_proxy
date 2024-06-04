# Use the official Dart image
FROM dart:stable

# Set the working directory
WORKDIR /app

# Copy the pubspec and run pub get to cache dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the application
COPY . .

# Expose the port
EXPOSE 8080

# Start the server
CMD ["dart", "run", "server.dart"]
