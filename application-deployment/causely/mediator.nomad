variable "datacenters" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}

variable "gateway_host" {
  type = string
}

variable "gateway_token" {
  type = string
}

variable "mediator_image" {
  type = string
}

variable "mediator_cpu" {
  type = number
}

variable "mediator_memory" {
  type = number
}

variable "ml_image" {
  type = string
}

variable "ml_cpu" {
  type = number
}

variable "ml_memory" {
  type = number
}

variable "nfs_server" {
  type = string
}

variable "nfs_path" {
  type = string
}

job "mediator" {
  datacenters = var.datacenters

  type = "service"

  update {
    max_parallel     = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert      = false
    canary           = 0
  }

  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "5m"
  }

  group "causely-mediator" {
    count = 1

    network {
      port "grpc-otlp" {}
      port "http-datadog" {}
      port "webserver" {}
      port "webserver2" {}
    }

    task "mediator" {
      driver = "docker"

      config {
        image   = var.mediator_image
        command = "/bin/mediator"
        args    = ["-config", "/config/config.yaml"]
        port_map {
          grpc-otlp     = 8360
          http-datadog  = 8125
          webserver     = 8082
          grpc          = 50051
        }
      }

      resources {
        cpu    = var.mediator_cpu
        memory = var.mediator_memory
      }

      service {
        name = "mediator"
        port = "webserver"
        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "1s"
        }
      }

      template {
        destination = "/config/config.yaml"
        data = <<EOF
        gateway:
          host: var.mediator_image
          port: 443
          token: var.mediator_token
          tls: true
          insecure: false

        label_semconv:
          entities:
            - entity_type: "BusinessApplication"
              labels:
                - "app.kubernetes.io/part-of"
          scopes:
            geography:
              - "partition"
            environment:
              - "environment"
            team:
              - "team_name"

        ml:
          enabled: true
          host: ml
          port: 8361
          token: ""
          tls: false
          insecure: true

        persistence:
          enabled: true
          path: /local/mediator

        global:
          host_root: /host
          cluster_name: var.cluster_name

        server:
          listen_port: 50051

        webserver:
          port: 8082

        time_series:
          hostname: victoriametrics
          port: 8428

        scrapers:
          - type: Consul
            enabled: true
            sync_interval: 60s
            logging:
              scraper:
                level: debug
              repository:
                level: info
            service_endpoint: http://consul-server.consul.svc.cluster.local:8500

          - type: Nomad
            enabled: true
            sync_interval: 60s
            logging:
              scraper:
                level: info
              repository:
                level: info
            nomad_api_endpoint: http://host.docker.internal:4646
            consul_api_endpoint: http://host.docker.internal:8500
            token: ""

          - type: Prometheus
            enabled: true
            sync_interval: 20s
            logging:
              scraper:
                level: info
              repository:
                level: info
            servers:
              prometheus:
                endpoint: http://prometheus-operated.monitoring.svc.cluster.local:9090
                exporters:
                  - go-applications
                  - java-applications
                  - python-applications
                  - postgres
                  - redis
                  - kafka
                  - rabbitmq
            exporters:
              go-applications:
                entities:
                  - attributes:
                      namespace:
                        label: ["yext_site"]
                      name:
                        label: [job"]
                    entityType: ApplicationInstance
                    metrics:
                      - attribute: MutexWaitSecondsTotal
                        query: sum by (yext_site, job) (go_sync_mutex_wait_total_seconds_total{job!=""})

                      - attribute: UserCPUSecondsTotal
                        query: sum by (yext_site, job) (go_cpu_classes_user_cpu_seconds_total{job!=""})

                      - attribute: GCTotalCPUSecondsTotal
                        query: sum by (yext_site, job) (go_cpu_classes_gc_total_cpu_seconds_total{job!=""})

                      - attribute: DBConnectionUsage
                        query: sum by (yext_site, job) (avg_over_time(gorm_dbstats_open_connections[15m]))

                      - attribute: DBQueryDuration
                        query: "sum by (yext_site, job) (rate(postgres_queries_sum[1m]) / (rate(postgres_queries_count[1m]) > 0 or (rate(postgres_queries_count[1m]) + 1)))"

                      - attribute: GoMaxProcs
                        query: sum by (yext_site, job) (go_sched_gomaxprocs_threads{job!=""})

                    connections: # connections represent connection between entities based on the link Query
                      - entityType: DatabaseServerInstance
                        relation: LayeredOver

              java-applications:
                entities:
                  - attributes:
                      namespace:
                        label: ["yext_site"]
                      name:
                        label: [job"]
                    entityType: ApplicationInstance
                    metrics:
                      - attribute: JavaHeapCapacity
                        query: jvm_memory_bytes_max{area="heap"} or jvm_memory_max_bytes{area="heap"}

                      - attribute: JavaHeapUsage
                        query: jvm_memory_bytes_used{area="heap"} or jvm_memory_used_bytes{area="heap"}

                      - attribute: UserCPUSecondsTotal
                        query: sum by (yext_site, job) (process_cpu_seconds_total{job!=""})

                      - attribute: GCTotalCPUSecondsTotal
                        query: sum by (yext_site, job) (jvm_gc_collection_seconds_sum{job!=""})

              python-applications:
                entities:
                  - attributes:
                      namespace:
                        label: ["yext_site"]
                      name:
                        label: [job"]
                    entityType: ApplicationInstance
                    metrics:
                      - attribute: RequestsTotal
                        query: sum by (yext_site, job) (rate(request_result_total[1m]))
              postgres:
                entities:
                  - entityType: DatabaseServerInstance
                    metrics:
                      - attribute: DBConnectionUsage
                        query: sum(db_client_connections_total) by (yext_site, datasource)

                      - attribute: DBQueryDuration
                        query: max by (yext_site, data_source) (db_query_duration)
                    attributes:
                      namespace:
                        label: ["yext_site"]
                      name:
                        label: [datasource"]
                    connections: # connections represent connection between entities based on the link Query
                      - entityType: ApplicationInstance
                        relation: Clients
              rabbitmq:
                entities:
                  - entityType: BrokerInstance
                    metrics:
                      - attribute: MemoryUsage
                        query: rabbitmq_process_resident_memory_bytes

                      - attribute: MemoryCapacity
                        query: rabbitmq_resident_memory_limit_bytes

                      - attribute: FileDescriptorUsage
                        query: rabbitmq_process_open_fds

                      - attribute: FileDescriptorCapacity
                        query: rabbitmq_process_max_fds

                    attributes:
                      namespace:
                        label: ["yext_site"]
                      name:
                        label: [instance"]
                  - entityType: Topic
                    metrics:
                      - attribute: QueueDepth
                        query: rabbitmq_detailed_queue_messages
                    attributes:
                      id:
                        label: ["queue"]
                    relationships:
                      - type: LayeredOver
                        relation: LayeredOver
                        relatedEntityType: BrokerInstance
                        attributes:
                          label: instance
              kafka:
                entities:
                  - entityType: Topic  # Monitor the Lag but the attribute is on the AsyncAccess
                    metrics:
                      - attribute: Lag
                        query: kafka_consumergroup_lag
                        labels:    # labels are used to find the reference AsyncAccess Entity
                          - labelKey: DestinationId
                            promKey: $id
                          - labelKey: ConsumerGroup
                            promKey: consumergroup
                        relatedEntityType: AsyncAccess
                    labels:  # labels are used to find the reference Topic Entity
                      - labelKey: Topic
                        promKey: topic
                      - labelKey: ClusterId
                        promKey: cluster
              redis:
                entities:
                  - entityType: CacheInstance
                    metrics:
                      - attribute: CacheSize
                        query: sum by (namespace) (redis_memory_used_bytes)

                      - attribute: CommandLatency
                        query: sum by (namespace) (rate(redis_commands_duration_seconds_total[1m])/rate(redis_commands_total[5m]))
                    attributes:
                      name:
                        label: ["namespace"]

          - type: OpenTelemetry
            enabled: true
            sync_interval: 20s
            port: 8360
            logging:
              scraper:
                level: info
              repository:
                level: info
            semconv:
              general:
                service.namespace:
                  - "deployment.site"
        EOF
      }

      volume_mount {
        volume      = "repository"
        destination = "/local"
      }
    }

    task "ml" {
      driver = "docker"

      config {
        image   = var.ml_image
        command = "/bin/sh"
        args    = ["-c", "python3 mediator/main.py --config /config/config.yaml"]
        port_map {
          grpc      = 8361
          webserver2 = 8081
        }
      }

      resources {
        cpu    = var.ml_cpu
        memory = var.ml_memory
      }

      service {
        name = "ml"
        port = "webserver2"
        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "1s"
        }
      }

      template {
        destination = "/config/config_ml.yaml"
        data = <<EOF
        grpc:
          host: "0.0.0.0"
          port: 8361
          max_send_msg_size: 33554432 # 32MB
          max_receive_msg_size: 33554432 # 32MB

        # victoriametrics configuration
        victoriametrics:
          endpoint: "http://victoriametrics:8428"
          period: "24h"
          step: "5m"
          batch_size: 10
          max_backoff_minutes: 20 # 20 minutes max backoff
          initial_backoff_seconds: 1 # Initial backoff delay
          backoff_multiplier: 2 # Expontential backoff factor
          jitter: 0.1 # Jitter factor

        # Model settings
        model:
          prophet:
            args:
              daily_seasonality: true
              weekly_seasonality: false
              yearly_seasonality: false
              seasonality_mode: "multiplicative"
              interval_width: 0.99
              changepoint_range: 0.8
            horizon: 12 # 1 hour forecast with 5 minutes interval
            freq: "5min"

        # webserver settings
        webserver:
          host: "0.0.0.0"
          port: 8081
        EOF
      }
    }

    volume "repository" {
      type = "csi"
      source = "nfs"
      attachment_mode = "file-system"
      access_mode = "multi-node-multi-writer"
    }
  }
}