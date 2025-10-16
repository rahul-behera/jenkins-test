pipeline {
    agent any
    
    parameters {
        string(
            name: 'BRANCH_NAME', 
            defaultValue: 'main', 
            description: 'Git branch to deploy'
        )
        choice(
            name: 'PROJECT_CHOICE',
            choices: ['ALL', 'CPE_BACKEND', 'CPE_FRONTEND', 'OS_EOL'],
            description: 'Select which project to deploy (ALL for all projects)'
        )
        booleanParam(
            name: 'SIMULATE_CHANGES',
            defaultValue: false,
            description: 'Simulate changes in repositories for testing'
        )
    }
    
    environment {
        // Test environment paths
        TEST_ROOT = '/tmp/test-env'
        CPE_BACKEND_PROJECT_PATH = "${TEST_ROOT}/cpe-backend"
        CPE_FRONTEND_PROJECT_PATH = "${TEST_ROOT}/cpe-frontend"
        OS_EOL_PROJECT_PATH = "${TEST_ROOT}/os-eol"
        
        // Test service names (we'll simulate service operations)
        CPE_BACKEND_SERVICE = 'test-cpe-backend.service'
        CPE_FRONTEND_SERVICE = 'test-cpe-frontend.service'
        OS_EOL_SERVICE = 'test-os-eol.service'
        
        // Mock server info for testing
        REMOTE_SERVER = 'localhost'
        REMOTE_USER = System.getProperty('user.name')
    }
    
    stages {
        stage('Setup Test Environment') {
            steps {
                script {
                    echo "🚀 Setting up test environment..."
                    
                    // Make setup script executable and run it
                    sh """
                        chmod +x setup_test_env.sh
                        ./setup_test_env.sh
                    """
                    
                    if (params.SIMULATE_CHANGES) {
                        echo "📝 Simulating changes in repositories..."
                        simulateChanges()
                    }
                }
            }
        }
        
        stage('Check for Changes') {
            steps {
                script {
                    def hasChanges = false
                    def changedProjects = []
                    
                    def allProjects = [
                        [key: 'CPE_BACKEND', name: 'CPE Backend', path: env.CPE_BACKEND_PROJECT_PATH, service: env.CPE_BACKEND_SERVICE],
                        [key: 'CPE_FRONTEND', name: 'CPE Frontend', path: env.CPE_FRONTEND_PROJECT_PATH, service: env.CPE_FRONTEND_SERVICE],
                        [key: 'OS_EOL', name: 'OS EOL', path: env.OS_EOL_PROJECT_PATH, service: env.OS_EOL_SERVICE]
                    ]
                    
                    // Filter projects based on user selection
                    def projectPaths = []
                    if (params.PROJECT_CHOICE == 'ALL') {
                        projectPaths = allProjects
                    } else {
                        projectPaths = allProjects.findAll { it.key == params.PROJECT_CHOICE }
                    }
                    
                    echo "🔍 Selected projects for deployment: ${projectPaths.collect { it.name }.join(', ')}"
                    
                    for (project in projectPaths) {
                        echo "Checking for changes in ${project.name} at ${project.path}"
                        
                        try {
                            // In test mode, we'll just check if the directory exists and has git
                            sh """
                                cd ${project.path}
                                git status
                            """
                            
                            // For testing, we'll consider all selected projects as changed
                            hasChanges = true
                            changedProjects.add(project)
                            echo "✓ Test changes detected in ${project.name}"
                            
                        } catch (Exception e) {
                            echo "⚠ Error checking ${project.name}: ${e.getMessage()}"
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                    
                    if (!hasChanges) {
                        echo "ℹ No changes detected in any project. Skipping deployment."
                        currentBuild.result = 'SUCCESS'
                        return
                    }
                    
                    // Store changed projects for later stages
                    env.HAS_CHANGES = 'true'
                    env.CHANGED_PROJECTS = changedProjects.collect { "${it.name}:${it.path}:${it.service}" }.join(',')
                }
            }
        }
        
        stage('Validate Project Paths') {
            when { environment name: 'HAS_CHANGES', value: 'true' }
            steps {
                script {
                    def changedProjectsData = env.CHANGED_PROJECTS.split(',')
                    def changedProjects = []
                    
                    for (projectData in changedProjectsData) {
                        def parts = projectData.split(':')
                        changedProjects.add([name: parts[0], path: parts[1], service: parts[2]])
                    }
                    
                    echo "🔍 Validating test projects..."
                    
                    for (project in changedProjects) {
                        echo "Validating ${project.name} at ${project.path}"
                        
                        sh """
                            test -d ${project.path} || (echo "Error: Directory ${project.path} does not exist" && exit 1)
                            test -d ${project.path}/.git || (echo "Error: ${project.path} is not a git repository" && exit 1)
                            cd ${project.path}
                            echo "Current directory: \$(pwd)"
                            echo "Git status:"
                            git status --porcelain
                            echo "Current branch:"
                            git branch --show-current
                        """
                        
                        echo "✓ ${project.name} validation successful"
                    }
                }
            }
        }
        
        stage('Simulate Service Operations') {
            when { environment name: 'HAS_CHANGES', value: 'true' }
            steps {
                script {
                    def changedProjectsData = env.CHANGED_PROJECTS.split(',')
                    def servicesToRestart = []
                    
                    for (projectData in changedProjectsData) {
                        def parts = projectData.split(':')
                        servicesToRestart.add([name: parts[0], service: parts[2]])
                    }
                    
                    echo """
🔄 Service Deployment Simulation:
Selected Project(s): ${params.PROJECT_CHOICE}
Services to Process: ${servicesToRestart.collect { "${it.name} (${it.service})" }.join(', ')}
"""
                    
                    for (serviceInfo in servicesToRestart) {
                        echo """
📋 Simulating restart for ${serviceInfo.name}:
➜ Stopping ${serviceInfo.service}...
➜ Starting ${serviceInfo.service}...
✓ Service restart simulation successful
"""
                    }
                    
                    // Show detailed deployment summary
                    echo """
📊 Test Deployment Summary:
═══════════════════
▸ Mode: ${params.PROJECT_CHOICE == 'ALL' ? 'Full Deployment' : 'Selective Deployment'}
▸ Projects Processed: ${servicesToRestart.size()}/${params.PROJECT_CHOICE == 'ALL' ? '3' : '1'}
▸ Selected Project(s): ${params.PROJECT_CHOICE}
▸ Services Simulated: ${servicesToRestart.collect { it.service }.join(', ')}
▸ Branch: ${params.BRANCH_NAME}
▸ Status: ${currentBuild.result ?: 'SUCCESS'}
"""
                }
            }
        }
    }
    
    post {
        always {
            echo """
🧪 Test Run Complete
══════════════════
▸ Build Status: ${currentBuild.result ?: 'SUCCESS'}
▸ Test Environment: ${env.TEST_ROOT}
▸ Selected Projects: ${params.PROJECT_CHOICE}
▸ Changes Simulated: ${params.SIMULATE_CHANGES}

Note: This was a test run. No actual services were affected.
"""
        }
    }
}

def simulateChanges() {
    // Function to simulate changes in test repositories
    def projectPaths = []
    
    if (params.PROJECT_CHOICE == 'ALL') {
        projectPaths = [
            env.CPE_BACKEND_PROJECT_PATH,
            env.CPE_FRONTEND_PROJECT_PATH,
            env.OS_EOL_PROJECT_PATH
        ]
    } else {
        switch(params.PROJECT_CHOICE) {
            case 'CPE_BACKEND':
                projectPaths = [env.CPE_BACKEND_PROJECT_PATH]
                break
            case 'CPE_FRONTEND':
                projectPaths = [env.CPE_FRONTEND_PROJECT_PATH]
                break
            case 'OS_EOL':
                projectPaths = [env.OS_EOL_PROJECT_PATH]
                break
        }
    }
    
    for (path in projectPaths) {
        sh """
            cd ${path}
            echo "// Test change \$(date)" >> app.js
            git add app.js
            git commit -m "Test change at \$(date)"
        """
    }
}
