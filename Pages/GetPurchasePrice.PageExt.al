/// <summary>
/// PageExtension TFB DS Get Purchase Price (ID 50504) extends Record Get Purchase Price //MyTargetPageId.
/// </summary>
pageextension 50504 "TFB DS Get Purchase Price" extends "Get Purchase Price" //MyTargetPageId
{
    layout
    {
        addafter("Direct Unit Cost")
        {
            field("TFB Postal Zone Surcharges"; Rec."TFB Postal Zone Surcharges")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Refering to table that is no longer used';
                ApplicationArea = All;
                DrillDown = true;
                DrillDownPageId = "TFB Vendor Zone Rate SubForm";
                ToolTip = 'Specifies postal zone surchases';
            }
        }
    }

    actions
    {
    }
}