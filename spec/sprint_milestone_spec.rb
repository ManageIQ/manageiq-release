RSpec.describe ManageIQ::Release::SprintMilestone do
  it ".sprints" do
    sprints = described_class.sprints(:as_of => 0).take(125)
    expect(sprints.first).to eq([8, Date.parse("2014-05-28"), Date.parse("2014-06-17")])
    last_date = Date.parse("2020-03-03")
    expect(sprints.last).to eq([132, last_date, last_date + 13.days])
  end
end
