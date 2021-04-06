tableextension 50502 "TFB DS Purchase Price" extends "Purchase Price" //MyTargetTableId
{
    fields
    {
        field(50503; "TFB Postal Zone Surcharges"; Integer)
        {
            Caption = 'No. Surcharges';

            FieldClass = FlowField;
            CalcFormula = Count ("TFB Vendor Zone Rate" where ("Vendor No." = field ("Vendor No.")));

        }

    }

}