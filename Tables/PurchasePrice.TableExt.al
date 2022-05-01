
/// <summary>
/// TableExtension TFB DS Purchase Price (ID 50502) extends Record Purchase Price //MyTargetTableId.
/// </summary>
tableextension 50502 "TFB DS Purchase Price" extends "Purchase Price" //MyTargetTableId
{

    fields
    {
        field(50503; "TFB Postal Zone Surcharges"; Integer)
        {
            Caption = 'No. Surcharges';
            ObsoleteState = Pending;
            ObsoleteReason = 'Refering to table that is no longer used';

            FieldClass = FlowField;
            CalcFormula = Count("TFB Vendor Zone Rate" where("Vendor No." = field("Vendor No.")));

        }

    }

}