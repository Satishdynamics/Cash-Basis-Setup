tableextension 50051 "SLGI CSH G/L Entry Ext" extends "G/L Entry"
{

    fields
    {
        field(70163480; "SLGI CSH Tax Entry"; Boolean)
        {
            Caption = 'Tax Entry';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(70163481; "SLGI CSH Exclude In Cash"; Boolean)
        {
            Caption = 'Exclude In Cash';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
    keys
    {
        key(SlgCCSHKey1; "SLGI CSH Exclude In Cash", "SLGI CSH Tax Entry")
        {

        }
    }
}

