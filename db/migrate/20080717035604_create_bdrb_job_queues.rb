class CreateBdrbJobQueues < ActiveRecord::Migration
  def self.up
    create_table :bdrb_job_queues do |t|
      t.column :args, :binary
      t.column :worker_name, :string
      t.column :worker_method, :string
      t.column :job_key, :string
      t.column :taken, :int
      t.column :finished, :int
      t.column :timeout, :int
      t.column :priority, :int
      t.column :submitted_at, :datetime
      t.column :started_at, :datetime
      t.column :finished_at, :datetime
      t.column :archived_at, :datetime
      t.column :tag, :string
      t.column :submitter_info, :string
      t.column :runner_info, :string
      t.column :worker_key, :string
    end
  end

  def self.down
    drop_table :bdrb_job_queues
  end
end
