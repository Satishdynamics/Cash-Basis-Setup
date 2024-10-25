tableextension 50061 "SLGI CSH Purch Inv Header" extends "Purch. Inv. Header"
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