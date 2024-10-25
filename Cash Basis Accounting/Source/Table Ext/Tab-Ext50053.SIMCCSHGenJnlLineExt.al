tableextension 50053 "SLGI CSH Gen Jnl Line Ext" extends "Gen. Journal Line"
{

    fields
    {
        field(70163480; "SLGI CSH Tax Entry"; Boolean)
        {
            Caption = 'Tax Entry';
            DataClassification = CustomerContent;
        }
        field(70163481; "SLGI CSH Exclude In Cash"; Boolean)
        {
            Caption = 'Exclude In Cash';
            DataClassification = CustomerContent;
            // Editable = false;
        }
        field(70163482; "SLGI CSH Exchange Rate Entry"; Boolean)
        {
            Caption = 'Exchange Rate Entry';
            DataClassification = CustomerContent;
        }
    }
}

