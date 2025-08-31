#!/bin/bash

# Performance Testing Script
# This script runs comprehensive performance tests

set -e

# Configuration
DURATION=${DURATION:-60}  # Test duration in seconds
CONCURRENT_USERS=${CONCURRENT_USERS:-10}  # Concurrent users
RAMP_UP=${RAMP_UP:-10}  # Ramp-up time in seconds
TARGET_URL=${TARGET_URL:-"http://localhost:3000"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v curl &> /dev/null; then
        log_error "curl is required for performance testing"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_warning "jq is recommended for JSON processing"
    fi

    if ! command -v bc &> /dev/null; then
        log_error "bc is required for calculations"
        exit 1
    fi

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

# Run load test with curl
run_load_test() {
    local test_name=$1
    local endpoint=$2
    local method=${3:-GET}
    local data=${4:-}

    log_info "Running $test_name test..."

    local start_time=$(date +%s.%3N)
    local success_count=0
    local total_count=0
    local response_times=()

    # Run test for specified duration
    local end_time=$(( $(date +%s) + DURATION ))

    while [ $(date +%s) -lt $end_time ]; do
        local request_start=$(date +%s.%3N)

        if [ "$method" = "POST" ]; then
            response=$(curl -s -w "%{http_code}:%{time_total}" -X POST -H "Content-Type: application/json" -d "$data" "$endpoint" 2>/dev/null)
        else
            response=$(curl -s -w "%{http_code}:%{time_total}" "$endpoint" 2>/dev/null)
        fi

        local http_code=$(echo "$response" | cut -d: -f1)
        local response_time=$(echo "$response" | cut -d: -f2)

        ((total_count++))

        if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
            ((success_count++))
            response_times+=("$response_time")
        fi

        # Small delay to prevent overwhelming the server
        sleep 0.1
    done

    local end_time_actual=$(date +%s.%3N)
    local actual_duration=$(echo "$end_time_actual - $start_time" | bc)

    # Calculate statistics
    local success_rate=$(echo "scale=2; $success_count * 100 / $total_count" | bc)
    local requests_per_second=$(echo "scale=2; $total_count / $actual_duration" | bc)

    # Calculate response time statistics
    if [ ${#response_times[@]} -gt 0 ]; then
        # Sort response times for percentile calculations
        IFS=$'\n' sorted_times=($(sort -n <<<"${response_times[*]}"))
        unset IFS

        local min_time=${sorted_times[0]}
        local max_time=${sorted_times[-1]}
        local median_time=${sorted_times[${#sorted_times[@]}/2]}

        # Calculate 95th percentile
        local p95_index=$(echo "${#sorted_times[@]} * 0.95" | bc | cut -d. -f1)
        local p95_time=${sorted_times[$p95_index]}

        # Calculate average
        local sum=0
        for time in "${response_times[@]}"; do
            sum=$(echo "$sum + $time" | bc)
        done
        local avg_time=$(echo "scale=3; $sum / ${#response_times[@]}" | bc)
    else
        local min_time=0
        local max_time=0
        local avg_time=0
        local median_time=0
        local p95_time=0
    fi

    # Print results
    echo ""
    log_info "=== $test_name Results ==="
    echo "Duration: ${actual_duration}s"
    echo "Total Requests: $total_count"
    echo "Successful Requests: $success_count"
    echo "Success Rate: ${success_rate}%"
    echo "Requests/Second: $requests_per_second"
    echo ""
    echo "Response Time Statistics:"
    echo "  Min: ${min_time}s"
    echo "  Max: ${max_time}s"
    echo "  Average: ${avg_time}s"
    echo "  Median: ${median_time}s"
    echo "  95th Percentile: ${p95_time}s"
    echo ""

    # Save results to file
    echo "$test_name,$actual_duration,$total_count,$success_count,$success_rate,$requests_per_second,$min_time,$max_time,$avg_time,$median_time,$p95_time" >> performance_results.csv
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

# Main execution
main() {
    log_info "🚀 Starting Performance Testing Suite"
    echo "Target URL: $TARGET_URL"
    echo "Duration: ${DURATION}s"
    echo "Concurrent Users: $CONCURRENT_USERS"
    echo ""

    check_prerequisites
    warm_up

    # Initialize results file
    echo "Test Name,Duration,Total Requests,Successful Requests,Success Rate,Requests/Second,Min Time,Max Time,Avg Time,Median Time,P95 Time" > performance_results.csv

    # Run test scenarios
    test_api_endpoints
    run_concurrent_test
    run_stress_test

    # Generate final report
    generate_report

    log_success "🎉 Performance testing completed!"
    log_info "Check performance_reports/ directory for detailed results"
}

# Handle script arguments
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
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --url URL          Target URL (default: http://localhost:3000)"
            echo "  --duration SEC     Test duration in seconds (default: 60)"
            echo "  --users NUM        Number of concurrent users (default: 10)"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main "$@"