# frozen_string_literal: true

THEMES_DIR_NAME = 'themes'
THEMES_ROOT = Rails.root + '/public/' + THEMES_DIR_NAME
ACCEPTABLE_THEME_CONTENT_TYPES = ['application/zip', 'application/x-zip', 'application/x-zip-compressed', 'application/x-gtar', 'application/x-gzip', 'application/x-tar', 'application/x-compressed-tar']
