import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0

import AtomicDEX.MarketMode 1.0

import "../../Components"
import "../../Constants"

FloatingBackground {
    id: root

    property alias field: input_volume.field
    property alias price_field: input_price.field
    property alias column_layout: form_layout
    readonly property string total_amount: API.app.trading_pg.total_amount

    readonly property bool can_submit_trade: valid_trade_info && !notEnoughBalanceForFees() && isValid()

    function getVolume() {
        return input_volume.field.text === '' ? '0' :  input_volume.field.text
    }

    function fieldsAreFilled() {
        return !General.isZero(getVolume())  && !General.isZero(getCurrentPrice())
    }

    function hasParentCoinFees() {
        return General.hasParentCoinFees(curr_trade_info)
    }

    function hasEnoughParentCoinForFees() {
        return General.isCoinEnabled("ETH") && API.app.do_i_have_enough_funds("ETH", curr_trade_info.erc_fees)
    }

    // Will move to backend
//    function higherThanMinTradeAmount() {
//        if(input_volume.field.text === '') return false
//        return parseFloat(sell_mode ? input_volume.field.text : total_amount) >= General.getMinTradeAmount()
//    }

//    function receiveHigherThanMinTradeAmount() {
//        if(input_volume.field.text === '') return false
//        return parseFloat(sell_mode ? total_amount : input_volume.field.text) >= General.getMinTradeAmount()
//    }

    function isValid() {
        let valid = true

        if(valid) valid = fieldsAreFilled()
        // Will move to backend
//        if(valid) valid = higherThanMinTradeAmount()
//        if(valid) valid = receiveHigherThanMinTradeAmount()

        if(valid) valid = !notEnoughBalance()
        if(valid) valid = API.app.do_i_have_enough_funds(base_ticker, General.formatDouble(getNeededAmountToSpend(input_volume.field.text)))
        if(valid && hasParentCoinFees()) valid = hasEnoughParentCoinForFees()

        return valid
    }

    function getMaxBalance() {
        if(General.isFilled(base_ticker))
            return API.app.get_balance(base_ticker)

        return "0"
    }

    function getMaxVolume() {
        // base in this orderbook is always the left side, so when it's buy, we want the right side balance (rel in the backend)
        const value = sell_mode ? API.app.trading_pg.orderbook.base_max_taker_vol.decimal :
                                  API.app.trading_pg.orderbook.rel_max_taker_vol.decimal

        if(General.isFilled(value))
            return value

        return getMaxBalance()
    }

    function reset() {
    }

    function buyWithNoPrice() {
        return !sell_mode && General.isZero(getCurrentPrice())
    }

    function capVolume() {
        if(inCurrentPage() && input_volume.field.acceptableInput) {
            // If price is 0 at buy side, don't cap it to 0, let the user edit
            if(buyWithNoPrice())
                return false

            const input_volume_value = parseFloat(input_volume.field.text)
            let amt = input_volume_value

            // Cap the value
            const cap_val = max_volume
            if(amt > cap_val)
                amt = cap_val


            // Set the field
            if(amt !== input_volume_value) {
                input_volume.field.text = General.formatDouble(amt)
                return true
            }
        }

        return false
    }

    function getNeededAmountToSpend(volume) {
        volume = parseFloat(volume)
        if(sell_mode) return volume
        else        return volume * parseFloat(getCurrentPrice())
    }

    function notEnoughBalance() {
        return parseFloat(getMaxVolume()) < General.getMinTradeAmount()
    }

    implicitHeight: form_layout.height

    ColumnLayout {
        id: form_layout
        width: parent.width

        ColumnLayout {
            Layout.alignment: Qt.AlignTop

            Layout.fillWidth: true
            spacing: 15

            // Top Line
            RowLayout {
                id: top_line
                spacing: 20
                Layout.topMargin: parent.spacing
                Layout.leftMargin: parent.spacing
                Layout.rightMargin: Layout.leftMargin
                Layout.alignment: Qt.AlignHCenter

                DefaultButton {
                    Layout.fillWidth: true
                    font.pixelSize: Style.textSize
                    text: qsTr("Sell %1", "TICKER").arg(left_ticker)
                    color: sell_mode ? Style.colorButtonEnabled.default : Style.colorButtonDisabled.default
                    colorTextEnabled: sell_mode ? Style.colorButtonEnabled.danger : Style.colorButtonDisabled.danger
                    font.weight: Font.Medium
                    onClicked: setMarketMode(MarketMode.Sell)
                }
                DefaultButton {
                    Layout.fillWidth: true
                    font.pixelSize: Style.textSize
                    text: qsTr("Buy %1", "TICKER").arg(left_ticker)
                    color: sell_mode ? Style.colorButtonDisabled.default : Style.colorButtonEnabled.default
                    colorTextEnabled: sell_mode ? Style.colorButtonDisabled.primary : Style.colorButtonEnabled.primary
                    font.weight: Font.Medium
                    onClicked: setMarketMode(MarketMode.Buy)
                }
            }


            HorizontalLine {
                Layout.fillWidth: true
            }


            Item {
                Layout.fillWidth: true
                Layout.leftMargin: top_line.Layout.leftMargin
                Layout.rightMargin: top_line.Layout.rightMargin
                Layout.bottomMargin: input_volume.field.font.pixelSize
                height: input_volume.height

                AmountFieldWithInfo {
                    id: input_price

                    width: parent.width

                    field.left_text: qsTr("Price")
                    field.right_text: right_ticker

                    field.text: API.app.trading_pg.price
                    field.onTextChanged: {
                        API.app.trading_pg.price = field.text
                    }

                    // Will move to backend
//                    function resetPrice() {
//                        if(orderIsSelected()) resetPreferredPrice()
//                    }

//                    field.onPressed: {
//                        resetPrice()
//                    }
//                    field.onFocusChanged: {
//                        if(field.activeFocus) resetPrice()
//                    }
                }

                DefaultText {
                    id: price_usd_value
                    anchors.right: input_price.right
                    anchors.top: input_price.bottom
                    anchors.topMargin: 7

                    text_value: General.getFiatText(input_price.field.text, right_ticker)
                    font.pixelSize: input_price.field.font.pixelSize

                    CexInfoTrigger {}
                }
            }


            Item {
                Layout.fillWidth: true
                Layout.leftMargin: top_line.Layout.leftMargin
                Layout.rightMargin: top_line.Layout.rightMargin
                Layout.bottomMargin: input_volume.field.font.pixelSize
                height: input_volume.height

                AmountFieldWithInfo {
                    id: input_volume
                    width: parent.width
                    enabled: !multi_order_enabled

                    field.left_text: qsTr("Volume")
                    field.right_text: left_ticker
                    field.placeholderText: sell_mode ? qsTr("Amount to sell") : qsTr("Amount to receive")

                    field.text: backend_volume
                    field.onTextChanged: {
                        setVolume(field.text)
                    }
                }

                DefaultText {
                    anchors.right: input_volume.right
                    anchors.top: input_volume.bottom
                    anchors.topMargin: price_usd_value.anchors.topMargin

                    text_value: General.getFiatText(input_volume.field.text, left_ticker)
                    font.pixelSize: input_volume.field.font.pixelSize

                    CexInfoTrigger {}
                }
            }

            DefaultSlider {
                id: input_volume_slider

                function getRealValue() {
                    return input_volume_slider.position * (input_volume_slider.to - input_volume_slider.from)
                }

                enabled: input_volume.field.enabled && !buyWithNoPrice() && to > 0
                property bool updating_from_text_field: false
                property bool updating_text_field: false
                Layout.fillWidth: true
                Layout.leftMargin: top_line.Layout.leftMargin
                Layout.rightMargin: top_line.Layout.rightMargin
                Layout.bottomMargin: top_line.Layout.rightMargin*0.5
                from: 0
                to: Math.max(0, parseFloat(max_volume))
                live: false

                value: backend_volume === "" ? 0 : parseFloat(backend_volume)

                onValueChanged: { if(pressed) setVolume(General.formatDouble(value)) }

                DefaultText {
                    visible: parent.pressed
                    anchors.horizontalCenter: parent.handle.horizontalCenter
                    anchors.bottom: parent.handle.top

                    text_value: General.formatDouble(input_volume_slider.getRealValue(), General.getRecommendedPrecision(input_volume_slider.to))
                    font.pixelSize: input_volume.field.font.pixelSize
                }

                DefaultText {
                    anchors.left: parent.left
                    anchors.top: parent.bottom

                    text_value: qsTr("Min")
                    font.pixelSize: input_volume.field.font.pixelSize
                }
                DefaultText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom

                    text_value: qsTr("Half")
                    font.pixelSize: input_volume.field.font.pixelSize
                }
                DefaultText {
                    anchors.right: parent.right
                    anchors.top: parent.bottom

                    text_value: qsTr("Max")
                    font.pixelSize: input_volume.field.font.pixelSize
                }
            }


            // Fees
            InnerBackground {
                id: bg
                Layout.fillWidth: true
                Layout.leftMargin: top_line.Layout.leftMargin
                Layout.rightMargin: top_line.Layout.rightMargin

                content: RowLayout {
                    width: bg.width
                    height: tx_fee_text.font.pixelSize * 4

                    ColumnLayout {
                        id: fees
                        visible: valid_trade_info && !General.isZero(getVolume())

                        Layout.leftMargin: 10
                        Layout.rightMargin: Layout.leftMargin
                        Layout.alignment: Qt.AlignLeft

                        DefaultText {
                            id: tx_fee_text
                            text_value: General.feeText(curr_trade_info, base_ticker, true, true)
                            font.pixelSize: Style.textSizeSmall1

                            CexInfoTrigger {}
                        }
                    }


                    DefaultText {
                        visible: !fees.visible

                        text_value: !visible ? "" :
                                    notEnoughBalance() ? (qsTr('Minimum fee') + ":     " + General.formatCrypto("", General.formatDouble(parseFloat(getMaxBalance()) - parseFloat(getMaxVolume())), base_ticker))
                                                        : qsTr('Fees will be calculated')
                        Layout.alignment: Qt.AlignCenter
                        font.pixelSize: tx_fee_text.font.pixelSize
                    }
                }
            }
        }

        // Total amount
        ColumnLayout {
            Layout.topMargin: 5
            Layout.fillWidth: true
            Layout.leftMargin: top_line.Layout.rightMargin
            Layout.rightMargin: Layout.leftMargin
            Layout.bottomMargin: layout_margin

            DefaultText {
                font.weight: Font.Medium
                font.pixelSize: Style.textSizeSmall3
                text_value: qsTr("Total") + ": " + General.formatCrypto("", total_amount, right_ticker)
            }

            DefaultText {
                text_value: General.getFiatText(total_amount, right_ticker)
                font.pixelSize: input_price.field.font.pixelSize

                CexInfoTrigger {}
            }
        }

        // Trade button
        DefaultButton {
            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: true
            Layout.leftMargin: top_line.Layout.rightMargin
            Layout.rightMargin: Layout.leftMargin
            Layout.bottomMargin: layout_margin

            button_type: sell_mode ? "danger" : "primary"

            width: 170

            text: qsTr("Start Swap")
            font.weight: Font.Medium
            enabled: !multi_order_enabled && can_submit_trade
            onClicked: confirm_trade_modal.open()
        }

        ColumnLayout {
            spacing: parent.spacing
            visible: errors.text_value !== ""

            Layout.alignment: Qt.AlignBottom
            Layout.fillWidth: true
            Layout.bottomMargin: layout_margin

            HorizontalLine {
                Layout.fillWidth: true
                Layout.bottomMargin: layout_margin
            }

            // Show errors
            DefaultText {
                id: errors
                Layout.leftMargin: top_line.Layout.rightMargin
                Layout.rightMargin: Layout.leftMargin
                Layout.fillWidth: true

                font.pixelSize: Style.textSizeSmall4
                color: Style.colorRed

                text_value: "Errors will be moved to backend"
                    // Will move to backend
//                            // Balance check can be done without price too, prioritize that for sell
//                            notEnoughBalance() ? (qsTr("Tradable (after fees) %1 balance is lower than minimum trade amount").arg(base_ticker) + " : " + General.getMinTradeAmount()) :

//                            // Fill the price field
//                            General.isZero(getCurrentPrice()) ? (qsTr("Please fill the price field")) :

//                            // Fill the volume field
//                            General.isZero(form_base.getVolume()) ? (qsTr("Please fill the volume field")) :


//                            // Trade amount is lower than the minimum
//                            (form_base.fieldsAreFilled() && !form_base.higherThanMinTradeAmount()) ? ((qsTr("Volume is lower than minimum trade amount")) + " : " + General.getMinTradeAmount()) :

//                            // Trade receive amount is lower than the minimum
//                            (form_base.fieldsAreFilled() && !form_base.receiveHigherThanMinTradeAmount()) ? ((qsTr("Receive volume is lower than minimum trade amount")) + " : " + General.getMinTradeAmount()) :

//                            // Fields are filled, fee can be checked
//                            notEnoughBalanceForFees() ?
//                                (qsTr("Not enough balance for the fees. Need at least %1 more", "AMT TICKER").arg(General.formatCrypto("", curr_trade_info.amount_needed, base_ticker))) :

//                            // Not enough ETH for fees
//                            (form_base.hasParentCoinFees() && !form_base.hasEnoughParentCoinForFees()) ? (qsTr("Not enough ETH for the transaction fee")) : ""
                          
            }
        }
    }
}
