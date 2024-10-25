tableextension 50062 "SLGI CSH Purch Cr Memo Header" extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(70163480; "SLGI CSH Overide Cash App Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Overide Cash Application Date';
        }
    }

}