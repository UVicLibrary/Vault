class FastUpdate::Change < ApplicationRecord
  attribute :count, :integer, default: 0

  # Exclude :old_label validation because user can paste in a deprecated URI without selecting a label.
  validates :old_uri, presence: true, format: { with: /\Ahttp:\/\/id.worldcat.org\/fast\/\d+\z/, message: "is not a valid URI." }
  # [Optional:] exclusion: { in: ->(repl) { repl.new_uris }, message: "New uri cannot be the same as old one" }
  validates :action, presence: true, inclusion: { in: ["replace", "delete"] }
  validates :new_uris, presence: { if: Proc.new { |r| r.action == "replace" }, message: "must be selected to replace the old one" }
  validates :collection_id, presence: true
end
