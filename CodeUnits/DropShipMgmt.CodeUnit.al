codeunit 50501 "TFB DS DropShip Mgmt"
{

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterUpdateShipToAddress', '', false, false)]
    /// <summary> 
    /// Description for HandleNewShipToAddress.
    /// </summary>
    /// <param name="PurchHeader">Parameter of type Record "Purchase Header".</param>
    local procedure HandleNewShipToAddress(var PurchHeader: Record "Purchase Header")
    begin
        //Check if ShipTo is a customer

        if (PurchHeader."Sell-to Customer No." <> '') then begin
            PurchHeader."TFB Instructions" := CopyCustomerInstructions(PurchHeader."Sell-to Customer No.");
            PurchHeader.Modify(false);
        end;


    end;

    [EventSubscriber(ObjectType::Codeunit, CodeUnit::"Purch.-Get Drop Shpt.", 'OnBeforePurchaseLineInsert', '', true, true)]
    /// <summary> 
    /// Event handler for Drop Ship Line Being Inserted directly on a Purchase Order
    /// </summary>
    /// <param name="PurchaseLine">Parameter of type Record "Purchase Line".</param>
    local procedure HandleDropShipLineInsert(var PurchaseLine: Record "Purchase Line")

    var
        Item: record Item;
        DeliveryZone: code[20];
        VendorSurcharge: decimal;

    begin
        if PurchaseLine."Drop Shipment" then begin
            DeliveryZone := GetDeliveryZoneForCustomerOrder(PurchaseLine."Sales Order No.");
            Item.Get(PurchaseLine."No.");


            If DeliveryZone <> '' then
                VendorSurcharge := GetVendorSurchargeforDeliveryZone(PurchaseLine."Buy-from Vendor No.", DeliveryZone, PurchaseLine."No.", PurchaseLine."Unit of Measure Code");

            If VendorSurcharge > 0 then
                PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + VendorSurcharge);


        end;

    end;




    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeInsertEvent', '', true, true)]
    /// <summary> 
    /// Checks if delivery surcharges should be applied in pricing calculation engine
    /// </summary>
    /// <param name="RunTrigger">Parameter of type Boolean.</param>
    /// <param name="Rec">Parameter of type Record "Requisition Line".</param>
    local procedure HandleOnBeforeInsertEventForRequisition(RunTrigger: Boolean; var Rec: Record "Requisition Line")

    var
        Item: record Item;
        PricingCU: codeunit "TFB Pricing Calculations";
        DeliveryZone: code[20];

        VendorSurcharge: decimal;
    begin


        if Rec.IsDropShipment() then begin
            DeliveryZone := GetDeliveryZoneForCustomerOrder(Rec."Sales Order No.");

            Item.Get(Rec."No.");

            If DeliveryZone <> '' then
                VendorSurcharge := GetVendorSurchargeforDeliveryZone(Rec."Vendor No.", DeliveryZone, Rec."No.", Rec."Unit of Measure Code");

            If VendorSurcharge <> 0 then begin
                Rec.Validate("Direct Unit Cost", Rec."Direct Unit Cost" + VendorSurcharge);
                Rec.CalcFields("TFB Price Unit Lookup");
                Rec."TFB Delivery Surcharge" := PricingCU.CalculatePriceUnitByUnitPrice(Rec."No.", Rec."Unit of Measure Code", Rec."TFB Price Unit Lookup", VendorSurcharge);
            end;
            Rec."TFB Sales External No." := GetSalesLineExternalNo(Rec."Sales Order No.");
        end;

    end;



    /// <summary> 
    /// Insert customer instructions into purchase order
    /// </summary>
    /// <param name="CustomerNo">Parameter of type Code[20].</param>
    /// <returns>Return variable "text[2048]".</returns>
    local procedure CopyCustomerInstructions(CustomerNo: Code[20]): text[2048]

    var
        Customer: record Customer;
        DelInstrBuilder: TextBuilder;

    begin


        begin
            DelInstrBuilder.Clear();
            If Customer.get(CustomerNo) then begin

                DelInstrBuilder.AppendLine(Customer."Delivery Instructions");
                If Customer.PalletAccountNo <> '' then begin
                    DelInstrBuilder.AppendLine(format(Customer."TFB Pallet Acct Type"));
                    DelInstrBuilder.AppendLine(Customer.PalletAccountNo);
                end;

            end;

            Exit(CopyStr(DelInstrBuilder.ToText(), 1, 2048));

        end;

    end;

    /// <summary> 
    /// Determine delivery zone for customer order
    /// </summary>
    /// <param name="SalesOrderNo">Parameter of type Code[20].</param>
    /// <returns>Return variable "Code[20]".</returns>
    local procedure GetDeliveryZoneForCustomerOrder(SalesOrderNo: Code[20]): Code[20]

    var
        TFBPostcodeZone: record "TFB Postcode Zone";
        SalesHeader: record "Sales Header";

    begin
        SalesHeader.SetRange("No.", SalesOrderNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if SalesHeader.FindFirst() then begin
            TFBPostcodeZone.SetRange("Customer Price Group", SalesHeader."Customer Price Group");
            If TFBPostcodeZone.FindFirst() then
                Exit(TFBPostcodeZone.Code)

        end;
    end;

    /// <summary> 
    /// Get external customer no for sales line
    /// </summary>
    /// <param name="SalesOrderNo">Parameter of type Code[20].</param>
    /// <returns>Return variable "Text[100]".</returns>
    local procedure GetSalesLineExternalNo(SalesOrderNo: Code[20]): Text[100];
    var
        SalesHeader: record "Sales Header";

    begin
        SalesHeader.SetRange("No.", SalesOrderNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        if SalesHeader.FindFirst() then
            Exit(SalesHeader."External Document No.");

    end;

    /// <summary> 
    /// Determine vendor surcharge based on delivery zone
    /// </summary>
    /// <param name="VendorNo">Parameter of type Code[20].</param>
    /// <param name="DeliveryZoneCode">Parameter of type Code[20].</param>
    /// <param name="ItemNo">Parameter of type Code[20].</param>
    /// <param name="UOM">Parameter of type Code[10].</param>
    /// <returns>Return variable "Decimal".</returns>
    local procedure GetVendorSurchargeforDeliveryZone(VendorNo: Code[20]; DeliveryZoneCode: Code[20]; ItemNo: Code[20]; UOM: Code[10]): Decimal


    var
        TFBVendorZoneRate: Record "TFB Vendor Zone Rate";
   
        TFBPricingCalculations: CodeUnit "TFB Pricing Calculations";
        SurchargeRateBase: Decimal;

    begin

        //First check check for Delivery Zone Rate for specific customer

        TFBVendorZoneRate.SetRange("Zone Code", DeliveryZoneCode);
        TFBVendorZoneRate.SetRange("Sales Type", TFBVendorZoneRate."Sales Type"::Item);
        TFBVendorZoneRate.SetRange("Vendor No.", VendorNo);
        TFBVendorZoneRate.SetRange("Sales Code", ItemNo);

        If TFBVendorZoneRate.FindFirst() then
            SurchargeRateBase := TFBPricingCalculations.CalculateUnitPriceByPriceUnit(ItemNo, UOM, TFBVendorZoneRate."Rate Type", TFBVendorZoneRate."Surcharge Rate")

        else begin
            Clear(TFBVendorZoneRate);
            TFBVendorZoneRate.SetRange("Zone Code", DeliveryZoneCode);
            TFBVendorZoneRate.SetRange("Sales Type", TFBVendorZoneRate."Sales Type"::All);
            TFBVendorZoneRate.SetRange("Vendor No.", VendorNo);

            If TFBVendorZoneRate.FindFirst() then
                //Return Base Rate
                SurchargeRateBase := TFBPricingCalculations.CalculateUnitPriceByPriceUnit(ItemNo, UOM, TFBVendorZoneRate."Rate Type", TFBVendorZoneRate."Surcharge Rate");

        end;
        Exit(SurchargeRateBase)
    end;


}