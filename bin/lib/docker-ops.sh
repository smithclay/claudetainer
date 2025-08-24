#!/bin/bash
# Docker Operations Library - Container management and queries

# Find containers for current directory
docker_find_project_containers() {
    docker ps -a --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" 2>/dev/null
}

# Find running containers for current directory
docker_find_running_project_containers() {
    docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" 2>/dev/null
}

# Find all claudetainer containers
docker_find_all_claudetainer_containers() {
    docker ps -a --filter "label=devcontainer.type=claudetainer" --format "{{.Names}}" 2>/dev/null
}

# Get container name for current project
docker_get_project_container_name() {
    docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" | head -1
}

# Check if Docker is running
docker_is_running() {
    if ui_command_exists docker; then
        docker info >/dev/null 2>&1
        return $?
    else
        return 1
    fi
}

# List all containers with details
docker_list_containers() {
    echo -e "CONTAINER ID\tNAMES\tPORTS\tSTATUS\tLOCAL_FOLDER"
    docker ps -q | while read -r cid; do
        short_id=$(echo "$cid" | cut -c1-12)
        name=$(docker inspect --format '{{.Name}}' "$cid" | sed 's/^\///')
        ports=$(docker inspect --format '{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{$p}}->{{(index $conf 0).HostPort}} {{end}}{{end}}' "$cid")
        status=$(docker inspect --format '{{.State.Status}}' "$cid")
        folder=$(docker inspect --format '{{index .Config.Labels "devcontainer.local_folder"}}' "$cid")
        echo -e "${short_id}\t${name}\t${ports}\t${status}\t${folder}"
    done | column -t
}

# Execute command in project container
docker_exec_in_container() {
    local container_name="$1"
    shift
    local command="$*"

    if [[ -n $container_name ]]; then
        docker exec "$container_name" sh -c "$command" 2>/dev/null
    else
        return 1
    fi
}

# Check if container has specific file/directory
docker_container_has_path() {
    local container_name="$1"
    local path="$2"

    if [[ -n $container_name ]]; then
        docker exec "$container_name" sh -c "ls $path >/dev/null 2>&1"
    else
        return 1
    fi
}

# Get container label value
docker_get_container_label() {
    local container_name="$1"
    local label="$2"

    if [[ -n $container_name ]]; then
        docker inspect "$container_name" --format "{{index .Config.Labels \"$label\"}}" 2>/dev/null
    fi
}

# Stop and remove containers for current project
docker_remove_project_containers() {
    local containers
    containers=$(docker_find_project_containers)
    local force="$1"

    if [[ -z $containers ]]; then
        ui_print_info "No claudetainer containers found for this directory"
        return 0
    fi

    ui_print_info "Found containers: $containers"

    if [[ $force != "true" ]]; then
        read -p "Remove these containers? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            ui_print_info "Aborted container removal"
            return 1
        fi
    fi

    # Remove containers
    echo "$containers" | while read -r container; do
        ui_print_info "Stopping and removing container: $container"
        docker stop "$container" >/dev/null 2>&1 || true
        docker rm "$container" >/dev/null 2>&1 || true
    done
    ui_print_success "Removed containers"

    # Clean up port file when containers are removed
    if [[ -f ".devcontainer/claudetainer/.claudetainer-port" ]]; then
        rm -f ".devcontainer/claudetainer/.claudetainer-port"
        ui_print_success "Cleaned up port allocation file"
    fi
}

# Remove all claudetainer containers
docker_remove_all_claudetainer_containers() {
    local force="$1"
    local containers
    containers=$(docker_find_all_claudetainer_containers)

    if [[ -z $containers ]]; then
        ui_print_info "No claudetainer containers found"
        return 0
    fi

    ui_print_info "Found claudetainer containers:"
    echo "$containers" | while read -r container; do
        local folder
        folder=$(docker inspect --format '{{index .Config.Labels "devcontainer.local_folder"}}' "$container" 2>/dev/null)
        echo "  • $container (from: $folder)"
    done

    if [[ $force != "true" ]]; then
        read -p "Remove ALL claudetainer containers? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            ui_print_info "Aborted container removal"
            return 1
        fi
    fi

    # Remove containers
    echo "$containers" | while read -r container; do
        ui_print_info "Stopping and removing container: $container"
        docker stop "$container" >/dev/null 2>&1 || true
        docker rm "$container" >/dev/null 2>&1 || true
    done
    ui_print_success "Removed all claudetainer containers"
}

# Check Docker memory allocation and warn if insufficient for sub-agent workloads
# Args: $1 = "prompt" (default) or "no-prompt" for non-interactive mode
check_docker_memory_allocation() {
    local mode="${1:-prompt}"
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        ui_print_warning "Docker is not running - cannot check memory allocation"
        return 0
    fi

    # Get Docker memory limit in bytes (returns 0 if unlimited)
    local docker_memory_bytes
    docker_memory_bytes=$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo "0")

    # If memory is 0 (unlimited) or very large, try alternative method
    if [[ $docker_memory_bytes == "0" ]] || [[ $docker_memory_bytes -gt 68719476736 ]]; then # > 64GB suggests no limit
        # Try to get memory limit from Docker Desktop settings
        docker_memory_bytes=$(docker system info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
    fi

    if [[ $docker_memory_bytes == "0" ]]; then
        ui_print_info "Docker memory allocation: Unlimited (system memory available)"
        return 0
    fi

    # Convert bytes to GB
    local docker_memory_gb
    docker_memory_gb=$((docker_memory_bytes / 1024 / 1024 / 1024))

    # Recommended minimum for sub-agent workloads with 8GB Node.js heap
    local recommended_memory_gb=12

    ui_print_info "Docker memory allocation: ${docker_memory_gb}GB"

    if [[ $docker_memory_gb -lt $recommended_memory_gb ]]; then
        ui_print_warning "Docker memory allocation (${docker_memory_gb}GB) may be insufficient for sub-agent workloads"
        echo ""
        echo "⚠️  MEMORY WARNING:"
        echo "   - Current Docker memory: ${docker_memory_gb}GB"
        echo "   - Recommended minimum: ${recommended_memory_gb}GB"
        echo "   - Node.js heap limit: 8GB"
        echo ""
        echo "Sub-agent orchestration may run out of memory and crash."
        echo ""
        echo "To increase Docker memory:"
        echo "  • Docker Desktop: Settings → Resources → Memory → ${recommended_memory_gb}GB+"
        echo "  • Linux: Increase available system memory"
        echo ""

        if [[ $mode == "prompt" ]]; then
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                ui_print_error "Installation cancelled. Please increase Docker memory allocation."
                return 1
            fi
        else
            # In no-prompt mode (like doctor), just return failure status
            return 1
        fi
    else
        ui_print_success "Docker memory allocation is sufficient for sub-agent workloads"
    fi

    return 0
}
