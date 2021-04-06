pageextension 50504 "TFB DS Get Purchase Price" extends "Get Purchase Price" //MyTargetPageId
{
    layout
    {
        addafter("Direct Unit Cost")
        {
            field("TFB Postal Zone Surcharges"; Rec."TFB Postal Zone Surcharges")
            {
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