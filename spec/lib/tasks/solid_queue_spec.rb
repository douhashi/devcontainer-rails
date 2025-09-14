require "rails_helper"
require "rake"

RSpec.describe "solid_queue tasks", skip: "solid_queueのマイグレーションが必要" do
  before(:all) do
    Rake.application.rake_require "tasks/solid_queue"
    Rake::Task.define_task(:environment)
  end

  before do
    # Clear any existing jobs for clean tests
    if defined?(SolidQueue::Job)
      SolidQueue::Job.delete_all
      SolidQueue::FailedExecution.delete_all if defined?(SolidQueue::FailedExecution)
    end
  end

  describe "solid_queue:status" do
    let(:task) { Rake::Task["solid_queue:status"] }

    before { task.reenable }

    it "displays queue status information" do
      expect { task.invoke }.to output(/Queue Status/).to_stdout
    end

    context "when jobs exist" do
      before do
        # Create test job using Active Job
        GenerateMusicGenerationJob.perform_later(create(:music_generation))
      end

      it "shows job counts" do
        expect { task.invoke }.to output(/Total Jobs:/).to_stdout
      end
    end
  end

  describe "solid_queue:workers" do
    let(:task) { Rake::Task["solid_queue:workers"] }

    before { task.reenable }

    it "displays worker information" do
      expect { task.invoke }.to output(/Worker Status/).to_stdout
    end
  end

  describe "solid_queue:failed" do
    let(:task) { Rake::Task["solid_queue:failed"] }

    before { task.reenable }

    it "displays failed jobs information" do
      expect { task.invoke }.to output(/Failed Jobs/).to_stdout
    end
  end
end
