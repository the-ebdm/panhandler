#!/bin/bash

# Simple git hooks setup script
# No dependencies, no bullshit

echo "🔧 Setting up git hooks..."

# Make hooks executable if they exist
if [ -f ".git/hooks/pre-commit" ]; then
    chmod +x .git/hooks/pre-commit
    echo "✅ pre-commit hook enabled"
fi

if [ -f ".git/hooks/commit-msg" ]; then
    chmod +x .git/hooks/commit-msg  
    echo "✅ commit-msg hook enabled"
fi

echo "🎯 Git hooks are now active!"
echo ""
echo "📝 Commit message format: <type>[scope]: <description>"
echo "🔍 Pre-commit checks: large files, sensitive data, TypeScript"
echo ""
echo "💡 To bypass hooks (only if absolutely necessary):"
echo "   git commit --no-verify" 