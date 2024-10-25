tableextension 50060 "SLGI CSH Purchase Header" extends "Purchase Header"
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