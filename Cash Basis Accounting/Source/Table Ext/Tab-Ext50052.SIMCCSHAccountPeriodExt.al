tableextension 50052 "SLGI CSH Account Period Ext" extends "Accounting Period"
{
    fields
    {
        field(70163480; "SLGI CSH New Cash Fiscal Year"; Boolean)
        {
            Caption = 'New Cash Fiscal Year';
            DataClassification = CustomerContent;
        }
        field(70163481; "SLGI CSH Cash Closed"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Cash Closed';
        }
    }
}

