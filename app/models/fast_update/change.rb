class FastUpdate::Change < ApplicationRecord
  attribute :count, :integer, default: 0

  validates :old_label, presence: true
  validates :old_uri, presence: true
  # [Optional:] exclusion: { in: ->(repl) { repl.new_uris }, message: "New uri cannot be the same as old one" }
  validates :action, presence: true
  validates :new_uris, presence: { if: Proc.new { |r| r.action == "replace" }, message: "must be selected to replace the old one" }
  validates :collection_id, presence: true
end
