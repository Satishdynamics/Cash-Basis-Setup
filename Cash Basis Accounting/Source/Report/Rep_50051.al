report 50051 "SLGI CSH Create Cash Year"
{

    Caption = 'Create Cash Fiscal Year';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;


    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(StartingDate; FiscalYearStartDate)
                    {
                        Caption = 'Starting Date';

                        ApplicationArea = All;
                        trigger OnValidate();
                        begin

                            if not AccountingPeriod.Get(FiscalYearStartDate) then
                                Error(DateWrongText, FiscalYearStartDate)

                            else begin
                                AccountingPeriod2.SetRange("SLGI CSH New Cash Fiscal Year", true);
                                if AccountingPeriod2.FindLast() then begin
                                    AccountingPeriod2.SetRange("SLGI CSH New Cash Fiscal Year");
                                    AccountingPeriod2.SetRange("Starting Date", AccountingPeriod2."Starting Date", FiscalYearStartDate);
                                    NoOfPeriods := AccountingPeriod2.Count();
                                end;
                            end;
                        end;
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        Caption = 'No. of Periods';
                        ApplicationArea = All;

                        trigger OnValidate();
                        begin
                            FiscalYearStartDate := FindNextYear();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit();
        begin
            NoOfPeriods := 0;
        end;

        trigger OnOpenPage();
        var
        //SlgCrestSub: Codeunit "SLGI SUB Subscription";
        begin
            ///SlgCrestSub.CheckProductEnabled('CSH');

            NoOfPeriods := 12;

            FiscalYearStartDate := 0D;
            FiscalYearStartDate := FindNextYear;
            RequestOptionsPage.Update;
        end;
    }

    labels
    {
    }

    trigger OnInitReport();
    begin
        NoOfPeriods := 0;
    end;

    trigger OnPreReport();
    begin

        if AccountingPeriod.Get(FiscalYearStartDate) then begin
            AccountingPeriod."SLGI CSH New Cash Fiscal Year" := true;
            AccountingPeriod.Modify;
        end;
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriod2: Record "Accounting Period";
        NoOfPeriods: Integer;
        FiscalYearStartDate: Date;
        I: Integer;
        CalcDateTxt: Text[10];
        DateWrongText: Label 'Start date %1 does not exist!';

    local procedure FindNextYear() NewYearDate: Date;
    begin
        NewYearDate := 0D;

        AccountingPeriod.SetRange("SLGI CSH New Cash Fiscal Year", true);
        if AccountingPeriod.FindLast then begin
            AccountingPeriod.SetRange("SLGI CSH New Cash Fiscal Year");
            for I := 1 to NoOfPeriods do
                if AccountingPeriod.Next = 0 then
                    exit(0D);
            NewYearDate := AccountingPeriod."Starting Date";
        end else
            NewYearDate := 0D;
    end;
}

