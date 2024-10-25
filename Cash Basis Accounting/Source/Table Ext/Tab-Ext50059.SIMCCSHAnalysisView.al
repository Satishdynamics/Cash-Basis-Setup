tableextension 50059 "SLGI CSH Analysis View" extends "Analysis View"
{
    fields
    {
        field(70163480; "SLGI CSH Cash Basis"; Boolean)
        {
            Caption = 'Cash Basis';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AnalysisViewEntry: Record "Analysis View Entry";
            begin
                Rec.TestField("Account Source", "Account Source"::"G/L Account");
                if "SLGI CSH Cash Basis" <> xRec."SLGI CSH Cash Basis" then begin
                    Rec."Last Entry No." := 0;
                    AnalysisViewEntry.SetRange("Analysis View Code", Rec.Code);
                    AnalysisViewEntry.DeleteAll();
                end;
                if not Rec."SLGI CSH Cash Basis" then
                    Rec."SLGI CSH Update on Cash Calc" := false;
            end;
        }
        field(70163481; "SLGI CSH Update on Cash Calc"; Boolean)
        {
            Caption = 'Update on Calculate Cash';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField("SLGI CSH Cash Basis");
            end;
        }
    }
}