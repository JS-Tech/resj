Given /^the card has a member$/ do
  create(:affiliation)
end

Given /^the member is authorized to edit the card$/ do
  create(:ownership, element_name: "cards", type_name: "on_entry", id_element: @card.id, right_update: true)
end

When /^I visit the team page of my card$/ do
  visit card_team_path(@card, locale: :fr)
end

When /^I check a member privilege box$/ do
  within "#privilege-form" do
    find(".card-edit").set(true)
  end
end

When /^I uncheck a member privilege box$/ do
  within "#privilege-form" do
    find(".card-edit").set(false)
  end
end

When /^I send the team form$/ do
  within "#privilege-form" do
    click_button "Enregistrer"
  end
end

Then /^I should see two checkboxes per user$/ do
  expect(page).to have_css("input#team-edit[type=checkbox]")
  expect(page).to have_css("input#card-edit[type=checkbox]")
end

Then /^I should see the member privilege box checked$/ do
  within "#privilege-form" do
    expect(find(".card-edit")).to be_checked
  end
end

Then /^I should see the member privilege box unchecked$/ do
  within "#privilege-form" do
    expect(find(".card-edit")).to_not be_checked
  end
end

Then /^I should see a checked checkbox for the member$/ do
  within "#privilege-form" do
    expect(find(".card-edit")).to be_checked
  end
end

Then /^I should see an unchecked checkbox for the member$/ do
  within "#privilege-form" do
    expect(find(".team-edit")).to_not be_checked
  end
end