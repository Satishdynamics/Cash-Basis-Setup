tableextension 50050 "SLGI CSH G/L Account Ext" extends "G/L Account"
{

    fields
    {
        field(70163480; "SLGI CSH Net Change Cash"; Decimal)
        {
            Caption = 'Net Change Cash';
            FieldClass = FlowField;
            BlankZero = true;
            CalcFormula = sum("SLGI Cash G/L Entry".Amount where("G/L Account No." = field("No."),
                                                             "G/L Account No." = field(filter(Totaling)),
                                                             "Posting Date" = field("Date Filter"),
                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Editable = false;

        }
        field(70163481; "SLGI CSH Balance at Date Cash"; Decimal)
        {
            Caption = 'Balance at Date Cash';
            FieldClass = FlowField;
            BlankZero = true;
            CalcFormula = sum("SLGI Cash G/L Entry".Amount where("G/L Account No." = field("No."),
                                                             "G/L Account No." = field(filter(Totaling)),
                                                             "Posting Date" = field(upperlimit("Date Filter")),
                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Editable = false;
        }
    }

}

