#!/bin/bash
# Docker Operations Library - Container management and queries

# Find containers for current directory
docker_find_project_containers() {
    docker ps -a --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" 2> /dev/null
}

# Find running containers for current directory
docker_find_running_project_containers() {
    docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" 2> /dev/null
}

# Find all claudetainer containers
docker_find_all_claudetainer_containers() {
    docker ps -a --filter "label=devcontainer.type=claudetainer" --format "{{.Names}}" 2> /dev/null
}

# Get container name for current project
docker_get_project_container_name() {
    docker ps --filter "label=devcontainer.local_folder=$(pwd)" --format "{{.Names}}" | head -1
}

# Check if Docker is running
docker_is_running() {
    if ui_command_exists docker; then
        docker info > /dev/null 2>&1
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

    if [[ -n "$container_name" ]]; then
        docker exec "$container_name" sh -c "$command" 2> /dev/null
    else
        return 1
    fi
}

# Check if container has specific file/directory
docker_container_has_path() {
    local container_name="$1"
    local path="$2"

    if [[ -n "$container_name" ]]; then
        docker exec "$container_name" sh -c "ls $path >/dev/null 2>&1"
    else
        return 1
    fi
}

# Get container label value
docker_get_container_label() {
    local container_name="$1"
    local label="$2"

    if [[ -n "$container_name" ]]; then
        docker inspect "$container_name" --format "{{index .Config.Labels \"$label\"}}" 2> /dev/null
    fi
}

# Stop and remove containers for current project
docker_remove_project_containers() {
    local containers=$(docker_find_project_containers)
    local force="$1"

    if [[ -z "$containers" ]]; then
        ui_print_info "No claudetainer containers found for this directory"
        return 0
    fi

    ui_print_info "Found containers: $containers"

    if [[ "$force" != "true" ]]; then
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
        docker stop "$container" > /dev/null 2>&1 || true
        docker rm "$container" > /dev/null 2>&1 || true
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
    local containers=$(docker_find_all_claudetainer_containers)

    if [[ -z "$containers" ]]; then
        ui_print_info "No claudetainer containers found"
        return 0
    fi

    ui_print_info "Found claudetainer containers:"
    echo "$containers" | while read -r container; do
        local folder=$(docker inspect --format '{{index .Config.Labels "devcontainer.local_folder"}}' "$container" 2> /dev/null)
        echo "  • $container (from: $folder)"
    done

    if [[ "$force" != "true" ]]; then
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
        docker stop "$container" > /dev/null 2>&1 || true
        docker rm "$container" > /dev/null 2>&1 || true
    done
    ui_print_success "Removed all claudetainer containers"
}
