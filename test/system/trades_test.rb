require "application_system_test_case"

class TradesTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    sign_in @user = users(:family_admin)

    @user.update!(show_sidebar: false, show_ai_sidebar: false)

    @account = accounts(:investment)

    visit_account_portfolio

    # Disable provider to focus on form testing
    Security.stubs(:provider).returns(nil)
  end

  test "can create buy transaction" do
    shares_qty = 25
    trade_date = Date.current

    open_new_trade_modal

    # When provider is nil, the field is manual_ticker
    fill_in "Ticker symbol", with: "AAPL"
    fill_in "Date", with: trade_date
    fill_in "Quantity", with: shares_qty
    fill_in "model[price]", with: 214.23

    perform_enqueued_jobs do
      click_button "Add transaction"
    end

    # Check if there are any form errors
    assert_no_text "can't be blank", wait: 2

    # Wait for the form submission to complete, then navigate to activity tab
    # The redirect goes to account page (with holdings tab), so we navigate to activity
    visit_trades

    within_trades do
      # Look for the specific trade with the quantity we created
      assert_text "Buy #{shares_qty}.0 shares of AAPL", wait: 5
    end
  end

  test "can create sell transaction" do
    qty = 10
    trade_date = Date.current
    aapl = @account.holdings.find { |h| h.security.ticker == "AAPL" }

    open_new_trade_modal

    select "Sell", from: "Type"
    fill_in "Ticker symbol", with: "AAPL"
    fill_in "Date", with: trade_date
    fill_in "Quantity", with: qty
    fill_in "model[price]", with: 215.33

    perform_enqueued_jobs do
      click_button "Add transaction"
    end

    # Check if there are any form errors
    assert_no_text "can't be blank", wait: 2

    # Wait for the form submission to complete, then navigate to activity tab
    # The redirect goes to account page (with holdings tab), so we navigate to activity
    visit_trades

    within_trades do
      # Look for the specific sell trade we created
      assert_text "Sell #{qty}.0 shares of AAPL", wait: 5
    end
  end

  private
    def open_new_trade_modal
      click_on "New transaction"
    end

    def within_trades(&block)
      within "#" + dom_id(@account, "entries"), &block
    end

    def visit_trades
      visit account_path(@account, tab: "activity")
    end

    def visit_account_portfolio
      visit account_path(@account, tab: "holdings")
    end
end
