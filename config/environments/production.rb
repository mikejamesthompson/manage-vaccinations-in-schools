# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Enable static file serving from the `/public` folder (turn off if using NGINX/Apache for it).
  config.public_file_server.enabled = true

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Don't force SSL for healthcheck endpoint.
  config.ssl_options = {
    redirect: {
      exclude: ->(request) { request.path =~ /ping/ }
    }
  }

  # Log to STDOUT by default
  config.logger =
    ActiveSupport::Logger
      .new($stdout)
      .tap { |logger| logger.formatter = ::Logger::Formatter.new }
      .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Info include generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "manage_vaccinations_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.action_mailer.default_url_options = {
    host:
      if Settings.is_review
        "#{ENV["HEROKU_APP_NAME"]}.herokuapp.com"
      else
        Settings.host
      end,
    protocol: "https"
  }
  config.action_mailer.delivery_method = :notify
  config.action_mailer.notify_settings = {
    api_key: Settings.govuk_notify.live_key
  }

  config.good_job.enable_cron = true
  config.good_job.cron = {
    bulk_update_patients_from_pds: {
      cron: "every day at 00:00 and 8:00 and 12:00 and 18:00",
      class: "BulkUpdatePatientsFromPDSJob",
      description: "Keep patient details up to date with PDS."
    },
    clinic_invitation: {
      cron: "every day at 9am",
      class: "ClinicSessionInvitationsJob",
      description: "Send school clinic invitation emails to parents"
    },
    consent_request: {
      cron: "every day at 9am",
      class: "SchoolConsentRequestsJob",
      description:
        "Send school consent request emails to parents for each session"
    },
    consent_reminder: {
      cron: "every day at 9am",
      class: "SchoolConsentRemindersJob",
      description:
        "Send school consent reminder emails to parents for each session"
    },
    session_reminder: {
      cron: "every day at 9am",
      class: "SchoolSessionRemindersJob",
      description: "Send school session reminder emails to parents"
    },
    remove_import_csv: {
      cron: "every day at 1am",
      class: "RemoveImportCSVJob",
      description: "Remove CSV data from old cohort and immunisation imports"
    },
    trim_active_record_sessions: {
      cron: "every day at 2am",
      class: "TrimActiveRecordSessionsJob",
      description: "Remove ActiveRecord sessions older than 30 days"
    }
  }
end
