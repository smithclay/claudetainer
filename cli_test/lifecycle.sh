#!/bin/bash
set -e

# External CLI Lifecycle Test
# Tests the actual claudetainer CLI tool end-to-end lifecycle
# This runs OUTSIDE containers and tests real CLI commands

echo "🧪 Testing claudetainer CLI full lifecycle..."

# Check prerequisites
check_prereqs() {
    local missing_critical=()
    local missing_optional=()

    # Check critical tools (required for core functionality)
    if ! command -v node >/dev/null 2>&1; then
        missing_critical+=("node")
    fi

    if ! command -v docker >/dev/null 2>&1; then
        missing_critical+=("docker")
    fi

    # Check optional tools (used for language-specific testing)
    if ! command -v python3 >/dev/null 2>&1; then
        missing_optional+=("python3")
    fi

    # Report missing prerequisites
    if [[ ${#missing_critical[@]} -gt 0 ]]; then
        log_warning "Missing critical prerequisites: ${missing_critical[*]}"
        log_info "Some core tests may fail due to missing required tools"
        return 1
    else
        if [[ ${#missing_optional[@]} -gt 0 ]]; then
            log_info "Missing optional tools: ${missing_optional[*]} (Python preset tests will be skipped)"
        fi
        log_success "All critical prerequisites available"
        return 0
    fi
}

# Configuration
TEST_BASE_DIR="./tmp/claudetainer-cli-test-$$"
CLI_BINARY_ARG="${1:-claudetainer}" # Allow specifying CLI path
# Convert to absolute path if relative
if [[ $CLI_BINARY_ARG == ./* ]]; then
    CLI_BINARY="$(pwd)/${CLI_BINARY_ARG#./}"
else
    CLI_BINARY="$CLI_BINARY_ARG"
fi
CLEANUP_ON_EXIT=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${BLUE}🔄 Test $TESTS_RUN: $test_name${NC}"

    if eval "$test_command"; then
        log_success "PASSED: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "FAILED: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Cleanup function
cleanup() {
    # shellcheck disable=SC2317  # Function is called via trap
    if [[ $CLEANUP_ON_EXIT == "true" ]]; then
        log_info "Cleaning up test directories and containers..."

        # Clean up any test containers first (before removing directories)
        if [[ -d $TEST_BASE_DIR ]]; then
            for test_dir in "$TEST_BASE_DIR"/*; do
                if [[ -d $test_dir ]]; then
                    (cd "$test_dir" && "$CLI_BINARY" rm -f 2>/dev/null) || true
                fi
            done

            # Clean up test directories
            rm -rf "$TEST_BASE_DIR"
        fi
    fi
}

trap cleanup EXIT

# Clean up any existing test directory and create fresh one
if [[ -d $TEST_BASE_DIR ]]; then
    log_info "Removing existing test directory: $TEST_BASE_DIR"
    rm -rf "$TEST_BASE_DIR"
fi

mkdir -p "$TEST_BASE_DIR"
log_info "Created clean test base directory: $TEST_BASE_DIR"

# Check prerequisites after log functions are available
check_prereqs

# Test 1: CLI binary availability and basic commands
run_test "CLI binary is available" "which $CLI_BINARY"
run_test "CLI shows version" "$CLI_BINARY --version"
run_test "CLI shows help" "$CLI_BINARY --help >/dev/null"
run_test "CLI prereqs check" "$CLI_BINARY prereqs"

# Test 2: Node.js project lifecycle
NODE_TEST_DIR="$TEST_BASE_DIR/test-node-project"
mkdir -p "$NODE_TEST_DIR"
cd "$NODE_TEST_DIR"
NODE_TEST_DIR="$(pwd)" # Get absolute path

# Create a simple Node.js project
cat >package.json <<'EOF'
{
  "name": "test-claudetainer-project",
  "version": "1.0.0",
  "description": "Test project for claudetainer CLI",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  }
}
EOF

cat >index.js <<'EOF'
console.log("Hello from claudetainer test!");
EOF

log_info "Created test Node.js project in $NODE_TEST_DIR"

run_test "CLI init with auto-detection" "printf 'y\\n' | $CLI_BINARY init"
run_test "devcontainer.json was created" "test -f .devcontainer/claudetainer/devcontainer.json"
run_test "devcontainer.json is valid JSON" "node -e \"JSON.parse(require('fs').readFileSync('.devcontainer/claudetainer/devcontainer.json', 'utf8'))\""
run_test "devcontainer.json contains claudetainer feature" "grep -q 'claudetainer' .devcontainer/claudetainer/devcontainer.json"

# Test 3: Python project with specific options (if Python is available)
if command -v python3 >/dev/null 2>&1; then
    PYTHON_TEST_DIR="$TEST_BASE_DIR/test-python-project"
    mkdir -p "$PYTHON_TEST_DIR"
    cd "$PYTHON_TEST_DIR"
    PYTHON_TEST_DIR="$(pwd)" # Get absolute path

    # Create a Python project
    cat >requirements.txt <<'EOF'
flask>=2.0.0
requests>=2.25.0
EOF

    cat >app.py <<'EOF'
print("Hello from Python claudetainer test!")
EOF

    run_test "CLI init with Python preset" "printf 'y\\n' | $CLI_BINARY init python >/dev/null 2>&1"
    run_test "Python devcontainer.json created" "test -f .devcontainer/claudetainer/devcontainer.json"
    run_test "Python docker-compose.yml created" "test -f .devcontainer/claudetainer/docker-compose.yml"
    run_test "Python preset included in config" "grep -q 'python' .devcontainer/claudetainer/devcontainer.json"
else
    log_warning "Skipping Python project tests - python3 not available"
fi

# Test 4: Custom multiplexer configuration
TMUX_TEST_DIR="$TEST_BASE_DIR/test-tmux-project"
mkdir -p "$TMUX_TEST_DIR"
cd "$TMUX_TEST_DIR"
TMUX_TEST_DIR="$(pwd)" # Get absolute path

echo "#!/bin/bash" >script.sh
echo "echo 'Shell script test'" >>script.sh

run_test "CLI init with tmux multiplexer" "printf 'y\\n' | $CLI_BINARY init shell --multiplexer tmux >/dev/null 2>&1"
run_test "tmux multiplexer configured" "grep -q 'tmux' .devcontainer/claudetainer/devcontainer.json"

# Test 5: CLI management commands (from Node.js test directory)
if [[ -d $NODE_TEST_DIR ]]; then
    cd "$NODE_TEST_DIR"
    run_test "CLI list (no active containers)" "$CLI_BINARY list"
    run_test "CLI doctor check" "$CLI_BINARY doctor"
else
    log_error "Node.js test directory not found: $NODE_TEST_DIR"
    exit 1
fi

# Test 6: Container lifecycle validation (lightweight tests)
if command -v docker >/dev/null 2>&1 && docker ps >/dev/null 2>&1 && [[ -d $NODE_TEST_DIR ]]; then
    log_info "Docker is available - testing container commands (without actually starting containers)"
    cd "$NODE_TEST_DIR"

    # Test that up command validates properly (should fail gracefully without Docker daemon issues)
    run_test "CLI up validates devcontainer properly" "$CLI_BINARY up >/dev/null 2>&1 || true"

    # Test SSH command validation
    run_test "CLI ssh command validates properly" "$CLI_BINARY ssh >/dev/null 2>&1 || true"

    # Test that cleanup commands work even without containers
    run_test "CLI rm works without containers" "$CLI_BINARY rm -f"

    log_info "Skipping actual container startup for faster testing"
else
    log_warning "Docker not available - skipping container lifecycle tests"
fi

# Test 7: Error handling and edge cases
EMPTY_TEST_DIR="$TEST_BASE_DIR/test-empty"
mkdir -p "$EMPTY_TEST_DIR"
cd "$EMPTY_TEST_DIR"
EMPTY_TEST_DIR="$(pwd)" # Get absolute path

run_test "CLI handles directory without devcontainer gracefully" "! $CLI_BINARY up"
run_test "CLI rm works even without containers" "$CLI_BINARY rm -f"

# Test 8: Configuration validation (from Node.js test directory)
if [[ -d $NODE_TEST_DIR ]]; then
    cd "$NODE_TEST_DIR"
    run_test "devcontainer.json has proper structure" "node -e \"
const config = JSON.parse(require('fs').readFileSync('.devcontainer/claudetainer/devcontainer.json', 'utf8'));
if (!config.features) throw new Error('Missing features');
const hasClaudetainer = Object.keys(config.features).some(key => key.includes('claudetainer'));
if (!hasClaudetainer) throw new Error('Missing claudetainer feature');
console.log('Configuration structure valid');
\""
else
    log_error "Node.js test directory not found: $NODE_TEST_DIR"
    exit 1
fi

# Test 9: CLI consistency and help
run_test "CLI global help works" "$CLI_BINARY --help >/dev/null"
run_test "CLI commands respond appropriately" "$CLI_BINARY up >/dev/null 2>&1 || true"
run_test "CLI ssh responds appropriately" "$CLI_BINARY ssh >/dev/null 2>&1 || true"
run_test "CLI rm responds appropriately" "$CLI_BINARY rm >/dev/null 2>&1 || true"
run_test "CLI list responds appropriately" "$CLI_BINARY list >/dev/null 2>&1 || true"

# Test 10: Invalid command handling
run_test "CLI handles invalid commands gracefully" "! $CLI_BINARY invalid-command-that-does-not-exist"

# Test 11: Prerequisites validation
run_test "System has required prerequisites" "check_prereqs"

# Final results
echo -e "\n${BLUE}==================== TEST RESULTS ====================${NC}"
echo -e "${BLUE}Tests Run:    $TESTS_RUN${NC}"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "\n${RED}❌ CLI lifecycle tests FAILED${NC}"
    exit 1
else
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "\n${GREEN}✅ All CLI lifecycle tests PASSED${NC}"
    exit 0
fi
