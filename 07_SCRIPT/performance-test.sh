#!/bin/bash

# Performance Testing Script
# This script runs comprehensive performance tests

set -euo pipefail  # Exit on any error, undefined variables, or pipe failures

# =============================================================================
# CONFIGURATION
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default configuration
DEFAULT_DURATION=60
DEFAULT_CONCURRENT_USERS=10
DEFAULT_RAMP_UP=10
DEFAULT_TARGET_URL="http://localhost:3000"
DEFAULT_REQUEST_TIMEOUT=30
DEFAULT_MAX_RETRIES=3
DEFAULT_THINK_TIME_MIN=1
DEFAULT_THINK_TIME_MAX=3
DEFAULT_REPORT_FORMAT="csv"
DEFAULT_STRESS_TEST_ENABLED=false
DEFAULT_LOAD_TEST_ENABLED=true
DEFAULT_SPIKE_TEST_ENABLED=false

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_metric() {
    echo -e "${CYAN}[METRIC]${NC} $1"
}

# =============================================================================
# VERSION CHECKING FUNCTIONS
# =============================================================================

check_curl_version() {
    if ! command -v curl &> /dev/null; then
        log_error "curl is required for performance testing"
        return 1
    fi

    local version
    version=$(curl --version | head -1 | sed 's/curl \([0-9.]*\).*/\1/')
    local required="7.50.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "curl version $version is below required $required"
        return 1
    fi

    log_success "curl version: $version"
}

check_jq_version() {
    if ! command -v jq &> /dev/null; then
        log_warning "jq is recommended for JSON processing"
        return 0
    fi

    local version
    version=$(jq --version | sed 's/jq-//')
    local required="1.5"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_warning "jq version $version is below recommended $required"
    fi

    log_success "jq version: $version"
}

check_bc_version() {
    if ! command -v bc &> /dev/null; then
        log_error "bc is required for calculations"
        return 1
    fi

    local version
    version=$(bc --version | head -1 | sed 's/bc \([0-9.]*\).*/\1/')
    local required="1.06"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "bc version $version is below required $required"
        return 1
    fi

    log_success "bc version: $version"
}

# =============================================================================
# CONFIGURATION FUNCTIONS
# =============================================================================

load_configuration() {
    # Load environment variables safely
    if [ -f ".env" ]; then
        log_info "Loading environment configuration..."
        set -a
        source .env
        set +a
        log_success "Environment variables loaded"
    fi

    # Load performance test configuration
    local config_file="06_CONFIG/performance.config"
    if [ -f "$config_file" ]; then
        log_info "Loading performance test configuration..."
        source "$config_file"
        log_success "Performance configuration loaded"
    else
        log_warning "Performance config not found at $config_file. Using defaults..."
    fi

    # Set defaults for unset variables
    DURATION=${DURATION:-$DEFAULT_DURATION}
    CONCURRENT_USERS=${CONCURRENT_USERS:-$DEFAULT_CONCURRENT_USERS}
    RAMP_UP=${RAMP_UP:-$DEFAULT_RAMP_UP}
    TARGET_URL=${TARGET_URL:-$DEFAULT_TARGET_URL}
    REQUEST_TIMEOUT=${REQUEST_TIMEOUT:-$DEFAULT_REQUEST_TIMEOUT}
    MAX_RETRIES=${MAX_RETRIES:-$DEFAULT_MAX_RETRIES}
    THINK_TIME_MIN=${THINK_TIME_MIN:-$DEFAULT_THINK_TIME_MIN}
    THINK_TIME_MAX=${THINK_TIME_MAX:-$DEFAULT_THINK_TIME_MAX}
    REPORT_FORMAT=${REPORT_FORMAT:-$DEFAULT_REPORT_FORMAT}
    STRESS_TEST_ENABLED=${STRESS_TEST_ENABLED:-$DEFAULT_STRESS_TEST_ENABLED}
    LOAD_TEST_ENABLED=${LOAD_TEST_ENABLED:-$DEFAULT_LOAD_TEST_ENABLED}
    SPIKE_TEST_ENABLED=${SPIKE_TEST_ENABLED:-$DEFAULT_SPIKE_TEST_ENABLED}
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_configuration() {
    log_step "Validating configuration..."

    # Validate URL
    if ! [[ $TARGET_URL =~ ^https?:// ]]; then
        log_error "Invalid TARGET_URL format: $TARGET_URL"
        return 1
    fi

    # Validate numeric parameters
    if ! [[ $DURATION =~ ^[0-9]+$ ]] || [ "$DURATION" -le 0 ]; then
        log_error "Invalid DURATION: $DURATION (must be positive integer)"
        return 1
    fi

    if ! [[ $CONCURRENT_USERS =~ ^[0-9]+$ ]] || [ "$CONCURRENT_USERS" -le 0 ]; then
        log_error "Invalid CONCURRENT_USERS: $CONCURRENT_USERS (must be positive integer)"
        return 1
    fi

    if ! [[ $RAMP_UP =~ ^[0-9]+$ ]] || [ "$RAMP_UP" -gt "$DURATION" ]; then
        log_error "Invalid RAMP_UP: $RAMP_UP (must be <= DURATION)"
        return 1
    fi

    log_success "Configuration validation passed"
}

# =============================================================================
# PREREQUISITE CHECK FUNCTIONS
# =============================================================================

check_prerequisites() {
    log_step "Checking prerequisites..."

    check_curl_version || return 1
    check_jq_version
    check_bc_version || return 1

    log_success "Prerequisites check passed"
}

# Warm up the application
warm_up() {
    log_info "Warming up the application..."

    for i in {1..5}; do
        curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL/health" || true
        sleep 1
    done

    log_success "Application warmed up"
}

# =============================================================================
# TEST EXECUTION FUNCTIONS
# =============================================================================

run_load_test() {
    local test_name=$1
    local endpoint=$2
    local method=${3:-GET}
    local data=${4:-}
    local headers=${5:-}

    log_info "Running $test_name test..."

    local start_time=$(date +%s.%3N)
    local success_count=0
    local total_count=0
    local error_count=0
    local response_times=()
    local status_codes=()

    # Run test for specified duration
    local end_time=$(( $(date +%s) + DURATION ))

    while [ $(date +%s) -lt $end_time ]; do
        local request_start=$(date +%s.%3N)

        # Build curl command
        local curl_cmd=(curl -s -w "%{http_code}:%{time_total}:%{size_download}" --max-time "$REQUEST_TIMEOUT")

        if [ "$method" = "POST" ]; then
            curl_cmd+=(-X POST -H "Content-Type: application/json" -d "$data")
        fi

        # Add custom headers
        if [ -n "$headers" ]; then
            curl_cmd+=(-H "$headers")
        fi

        curl_cmd+=("$endpoint")

        # Execute request
        local response
        if response=$("${curl_cmd[@]}" 2>/dev/null); then
            local http_code=$(echo "$response" | cut -d: -f1)
            local response_time=$(echo "$response" | cut -d: -f2)
            local response_size=$(echo "$response" | cut -d: -f3)

            ((total_count++))
            status_codes+=("$http_code")

            if [ "$http_code" = "200" ] || [ "$http_code" = "201" ] || [ "$http_code" = "202" ]; then
                ((success_count++))
                response_times+=("$response_time")
            else
                ((error_count++))
            fi
        else
            ((total_count++))
            ((error_count++))
            status_codes+=("000")  # Connection error
        fi

        # Think time between requests
        local think_time=$((THINK_TIME_MIN + RANDOM % (THINK_TIME_MAX - THINK_TIME_MIN + 1)))
        sleep "0.$think_time"
    done

    local end_time_actual=$(date +%s.%3N)
    local actual_duration=$(echo "$end_time_actual - $start_time" | bc)

    # Calculate statistics
    calculate_and_display_results "$test_name" "$actual_duration" "$total_count" "$success_count" "$error_count" response_times status_codes
}

calculate_and_display_results() {
    local test_name=$1
    local actual_duration=$2
    local total_count=$3
    local success_count=$4
    local error_count=$5
    local -n response_times_ref=$6
    local -n status_codes_ref=$7

    # Calculate rates
    local success_rate=$(echo "scale=2; $success_count * 100 / $total_count" | bc 2>/dev/null || echo "0")
    local error_rate=$(echo "scale=2; $error_count * 100 / $total_count" | bc 2>/dev/null || echo "0")
    local requests_per_second=$(echo "scale=2; $total_count / $actual_duration" | bc 2>/dev/null || echo "0")

    # Calculate response time statistics
    if [ ${#response_times_ref[@]} -gt 0 ]; then
        # Sort response times for percentile calculations
        IFS=$'\n' sorted_times=($(sort -n <<<"${response_times_ref[*]}"))
        unset IFS

        local min_time=${sorted_times[0]}
        local max_time=${sorted_times[-1]}
        local median_time=${sorted_times[${#sorted_times[@]}/2]}

        # Calculate percentiles
        local p95_index=$(echo "${#sorted_times[@]} * 0.95" | bc 2>/dev/null | cut -d. -f1 || echo "0")
        local p99_index=$(echo "${#sorted_times[@]} * 0.99" | bc 2>/dev/null | cut -d. -f1 || echo "0")
        local p95_time=${sorted_times[$p95_index]:-0}
        local p99_time=${sorted_times[$p99_index]:-0}

        # Calculate average
        local sum=0
        for time in "${response_times_ref[@]}"; do
            sum=$(echo "$sum + $time" | bc 2>/dev/null || echo "$sum + 0" | bc)
        done
        local avg_time=$(echo "scale=3; $sum / ${#response_times_ref[@]}" | bc 2>/dev/null || echo "0")
    else
        local min_time=0
        local max_time=0
        local avg_time=0
        local median_time=0
        local p95_time=0
        local p99_time=0
    fi

    # Display results
    echo ""
    log_info "=== $test_name Results ==="
    log_metric "Duration: ${actual_duration}s"
    log_metric "Total Requests: $total_count"
    log_metric "Successful Requests: $success_count"
    log_metric "Error Requests: $error_count"
    log_metric "Success Rate: ${success_rate}%"
    log_metric "Error Rate: ${error_rate}%"
    log_metric "Requests/Second: $requests_per_second"

    if [ ${#response_times_ref[@]} -gt 0 ]; then
        echo ""
        log_info "Response Time Statistics (seconds):"
        log_metric "  Min: ${min_time}"
        log_metric "  Max: ${max_time}"
        log_metric "  Average: ${avg_time}"
        log_metric "  Median: ${median_time}"
        log_metric "  95th Percentile: ${p95_time}"
        log_metric "  99th Percentile: ${p99_time}"
    fi

    # Status code distribution
    if [ ${#status_codes_ref[@]} -gt 0 ]; then
        echo ""
        log_info "Status Code Distribution:"
        printf '%s\n' "${status_codes_ref[@]}" | sort | uniq -c | sort -nr | while read -r count code; do
            log_metric "  $code: $count requests"
        done
    fi

    echo ""

    # Save results to file
    save_results_to_file "$test_name" "$actual_duration" "$total_count" "$success_count" "$error_count" "$success_rate" "$error_rate" "$requests_per_second" "$min_time" "$max_time" "$avg_time" "$median_time" "$p95_time" "$p99_time"
}

save_results_to_file() {
    local test_name=$1
    local actual_duration=$2
    local total_count=$3
    local success_count=$4
    local error_count=$5
    local success_rate=$6
    local error_rate=$7
    local requests_per_second=$8
    local min_time=$9
    local max_time=${10}
    local avg_time=${11}
    local median_time=${12}
    local p95_time=${13}
    local p99_time=${14}

    echo "$test_name,$actual_duration,$total_count,$success_count,$error_count,$success_rate,$error_rate,$requests_per_second,$min_time,$max_time,$avg_time,$median_time,$p95_time,$p99_time" >> performance_results.csv
}

# Run concurrent load test
run_concurrent_test() {
    log_info "Running concurrent load test with $CONCURRENT_USERS users..."

    local results_file="concurrent_test_$(date +%s).log"

    # Create a simple concurrent test script
    cat > concurrent_test.sh << 'EOF'
#!/bin/bash
TARGET_URL=$1
DURATION=$2
RESULTS_FILE=$3

start_time=$(date +%s)
end_time=$((start_time + DURATION))

while [ $(date +%s) -lt $end_time ]; do
    request_start=$(date +%s.%3N)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL" 2>/dev/null)
    request_end=$(date +%s.%3N)
    response_time=$(echo "$request_end - $request_start" | bc)

    echo "$http_code:$response_time" >> "$RESULTS_FILE"
    sleep 0.1
done
EOF

    chmod +x concurrent_test.sh

    # Start concurrent processes
    for i in $(seq 1 $CONCURRENT_USERS); do
        ./concurrent_test.sh "$TARGET_URL/api/status" "$DURATION" "results_$i.log" &
    done

    # Wait for all processes to complete
    wait

    # Aggregate results
    local total_requests=0
    local successful_requests=0
    local response_times=()

    for i in $(seq 1 $CONCURRENT_USERS); do
        while IFS=: read -r http_code response_time; do
            ((total_requests++))
            if [ "$http_code" = "200" ]; then
                ((successful_requests++))
                response_times+=("$response_time")
            fi
        done < "results_$i.log"
        rm "results_$i.log"
    done

    rm concurrent_test.sh

    # Calculate statistics
    local success_rate=$(echo "scale=2; $successful_requests * 100 / $total_requests" | bc)
    local requests_per_second=$(echo "scale=2; $total_requests / $DURATION" | bc)

    if [ ${#response_times[@]} -gt 0 ]; then
        local sum=0
        for time in "${response_times[@]}"; do
            sum=$(echo "$sum + $time" | bc)
        done
        local avg_time=$(echo "scale=3; $sum / ${#response_times[@]}" | bc)
    else
        local avg_time=0
    fi

    echo ""
    log_info "=== Concurrent Load Test Results ==="
    echo "Concurrent Users: $CONCURRENT_USERS"
    echo "Duration: ${DURATION}s"
    echo "Total Requests: $total_requests"
    echo "Successful Requests: $successful_requests"
    echo "Success Rate: ${success_rate}%"
    echo "Requests/Second: $requests_per_second"
    echo "Average Response Time: ${avg_time}s"
    echo ""
}

# Test API endpoints
test_api_endpoints() {
    log_info "Testing API endpoints..."

    # Test health endpoint
    run_load_test "Health Check" "$TARGET_URL/health"

    # Test API status endpoint
    run_load_test "API Status" "$TARGET_URL/api/status"

    # Test a heavier endpoint (if exists)
    if curl -s "$TARGET_URL/api/users" >/dev/null 2>&1; then
        run_load_test "Users API" "$TARGET_URL/api/users"
    fi
}

# Memory and CPU stress test
run_stress_test() {
    log_info "Running memory and CPU stress test..."

    # Test with larger payload
    local large_data='{"data":"'
    for i in {1..1000}; do
        large_data="${large_data}test_data_"
    done
    large_data="${large_data}test_data"}"

    run_load_test "Large Payload Test" "$TARGET_URL/api/test" "POST" "$large_data"
}

# Generate performance report
generate_report() {
    log_info "Generating performance report..."

    if [ -f "performance_results.csv" ]; then
        echo ""
        log_info "=== Performance Test Summary ==="
        echo "Test Results:"
        cat performance_results.csv
        echo ""

        # Calculate overall statistics
        local total_tests=$(wc -l < performance_results.csv)
        log_info "Total test scenarios run: $total_tests"

        # Archive results
        local timestamp=$(date +%Y%m%d_%H%M%S)
        mkdir -p performance_reports
        mv performance_results.csv "performance_reports/report_$timestamp.csv"

        log_success "Performance report saved to: performance_reports/report_$timestamp.csv"
    fi
}

# =============================================================================
# REPORTING FUNCTIONS
# =============================================================================

generate_report() {
    log_step "Generating performance report..."

    if [ ! -f "performance_results.csv" ]; then
        log_warning "No performance results found"
        return 1
    fi

    # Create reports directory
    mkdir -p performance_reports
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="performance_reports/report_${timestamp}"

    # Generate summary report
    {
        echo "Performance Test Report"
        echo "Generated: $(date)"
        echo "Target URL: $TARGET_URL"
        echo "Duration: ${DURATION}s"
        echo "Concurrent Users: $CONCURRENT_USERS"
        echo "Ramp Up: ${RAMP_UP}s"
        echo "========================================"
        echo ""
    } > "${report_file}.txt"

    # Process results
    local total_tests=0
    local total_requests=0
    local total_successful=0
    local avg_response_time=0

    while IFS=, read -r test_name duration total success error success_rate error_rate rps min_time max_time avg_time median_time p95_time p99_time; do
        if [ "$test_name" = "Test Name" ]; then
            continue
        fi

        ((total_tests++))
        total_requests=$((total_requests + total))
        total_successful=$((total_successful + success))

        {
            echo "Test: $test_name"
            echo "  Duration: ${duration}s"
            echo "  Total Requests: $total"
            echo "  Successful: $success"
            echo "  Failed: $error"
            echo "  Success Rate: ${success_rate}%"
            echo "  Error Rate: ${error_rate}%"
            echo "  Requests/sec: $rps"
            echo "  Response Times:"
            echo "    Min: ${min_time}s"
            echo "    Max: ${max_time}s"
            echo "    Avg: ${avg_time}s"
            echo "    Median: ${median_time}s"
            echo "    95th: ${p95_time}s"
            echo "    99th: ${p99_time}s"
            echo ""
        } >> "${report_file}.txt"

    done < performance_results.csv

    # Calculate overall statistics
    if [ $total_tests -gt 0 ]; then
        local overall_success_rate
        overall_success_rate=$(echo "scale=2; $total_successful * 100 / $total_requests" | bc 2>/dev/null || echo "0")

        {
            echo "========================================"
            echo "OVERALL SUMMARY"
            echo "========================================"
            echo "Total Tests Run: $total_tests"
            echo "Total Requests: $total_requests"
            echo "Total Successful: $total_successful"
            echo "Overall Success Rate: ${overall_success_rate}%"
            echo ""
        } >> "${report_file}.txt"
    fi

    # Generate JSON report if jq is available
    if command -v jq &> /dev/null; then
        generate_json_report "$report_file"
    fi

    # Archive results
    mv performance_results.csv "${report_file}.csv"

    log_success "Performance report generated: ${report_file}.txt"
    log_info "CSV data saved: ${report_file}.csv"
}

generate_json_report() {
    local base_file=$1
    local json_file="${base_file}.json"

    # Convert CSV to JSON
    {
        echo "{"
        echo '  "metadata": {'
        echo "    \"generated\": \"$(date -Iseconds)\","
        echo "    \"target_url\": \"$TARGET_URL\","
        echo "    \"duration\": $DURATION,"
        echo "    \"concurrent_users\": $CONCURRENT_USERS,"
        echo "    \"ramp_up\": $RAMP_UP"
        echo '  },'
        echo '  "tests": ['
    } > "$json_file"

    local first=true
    while IFS=, read -r test_name duration total success error success_rate error_rate rps min_time max_time avg_time median_time p95_time p99_time; do
        if [ "$test_name" = "Test Name" ]; then
            continue
        fi

        if [ "$first" = true ]; then
            first=false
        else
            echo "," >> "$json_file"
        fi

        cat >> "$json_file" << EOF
    {
      "name": "$test_name",
      "duration": $duration,
      "total_requests": $total,
      "successful_requests": $success,
      "error_requests": $error,
      "success_rate": $success_rate,
      "error_rate": $error_rate,
      "requests_per_second": $rps,
      "response_times": {
        "min": $min_time,
        "max": $max_time,
        "avg": $avg_time,
        "median": $median_time,
        "p95": $p95_time,
        "p99": $p99_time
      }
    }
EOF
    done < "${base_file}.csv"

    echo "  ]" >> "$json_file"
    echo "}" >> "$json_file"

    log_success "JSON report generated: $json_file"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    log_info "🚀 Starting Performance Testing Suite"
    echo "══════════════════════════════════════════════"
    log_info "Target URL: $TARGET_URL"
    log_info "Duration: ${DURATION}s"
    log_info "Concurrent Users: $CONCURRENT_USERS"
    log_info "Ramp Up: ${RAMP_UP}s"
    echo ""

    # Load and validate configuration
    load_configuration
    validate_configuration || exit 1

    # Check prerequisites
    check_prerequisites

    # Warm up the application
    warm_up

    # Initialize results file
    echo "Test Name,Duration,Total Requests,Successful Requests,Error Requests,Success Rate,Error Rate,Requests/Second,Min Time,Max Time,Avg Time,Median Time,P95 Time,P99 Time" > performance_results.csv

    # Run test scenarios
    if [ "$LOAD_TEST_ENABLED" = "true" ]; then
        test_api_endpoints
    fi

    if [ "$CONCURRENT_USERS" -gt 1 ]; then
        run_concurrent_test
    fi

    if [ "$STRESS_TEST_ENABLED" = "true" ]; then
        run_stress_test
    fi

    if [ "$SPIKE_TEST_ENABLED" = "true" ]; then
        run_spike_test
    fi

    # Generate final report
    generate_report

    echo ""
    log_success "🎉 Performance testing completed!"
    log_info "Check performance_reports/ directory for detailed results"
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --url)
                TARGET_URL="$2"
                shift 2
                ;;
            --duration)
                DURATION="$2"
                shift 2
                ;;
            --users)
                CONCURRENT_USERS="$2"
                shift 2
                ;;
            --ramp-up)
                RAMP_UP="$2"
                shift 2
                ;;
            --timeout)
                REQUEST_TIMEOUT="$2"
                shift 2
                ;;
            --format)
                REPORT_FORMAT="$2"
                shift 2
                ;;
            --stress-test)
                STRESS_TEST_ENABLED=true
                shift
                ;;
            --no-load-test)
                LOAD_TEST_ENABLED=false
                shift
                ;;
            --spike-test)
                SPIKE_TEST_ENABLED=true
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Performance Testing Script"
                echo ""
                echo "Options:"
                echo "  --url URL          Target URL (default: http://localhost:3000)"
                echo "  --duration SEC     Test duration in seconds (default: 60)"
                echo "  --users NUM        Number of concurrent users (default: 10)"
                echo "  --ramp-up SEC      Ramp-up time in seconds (default: 10)"
                echo "  --timeout SEC      Request timeout in seconds (default: 30)"
                echo "  --format FORMAT    Report format: csv, json, txt (default: csv)"
                echo "  --stress-test      Enable stress testing"
                echo "  --no-load-test     Disable load testing"
                echo "  --spike-test       Enable spike testing"
                echo "  --config FILE      Configuration file path"
                echo "  --help             Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --url https://api.example.com --duration 120 --users 50"
                echo "  $0 --stress-test --spike-test"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

# Parse command line arguments
parse_arguments "$@"

# Run main function
main