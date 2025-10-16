#!/bin/bash

# Create test directories
echo "Creating test project directories..."
mkdir -p /tmp/test-env/{cpe-backend,cpe-frontend,os-eol}

# Initialize git repositories in each directory
for dir in cpe-backend cpe-frontend os-eol; do
    cd /tmp/test-env/$dir
    echo "Setting up $dir test repository..."
    
    # Initialize git
    git init
    
    # Create some test files
    echo "# $dir Test Project" > README.md
    echo "console.log('Hello from $dir');" > app.js
    
    # Create test service file
    cat > test-$dir.service << EOL
[Unit]
Description=$dir test service
[Service]
ExecStart=/usr/bin/node app.js
[Install]
WantedBy=multi-user.target
EOL
    
    # Setup git
    git add .
    git config --local user.email "test@example.com"
    git config --local user.name "Test User"
    git commit -m "Initial commit for $dir"
    git branch -M main
done

echo "✅ Test environment created at /tmp/test-env"
echo "🔍 Directory structure:"
tree /tmp/test-env
