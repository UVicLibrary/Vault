RSpec.describe EdtfDateService do

  context 'when date is a single date with year-, month-, or day-specificity' do

    context 'and date is after 1000' do

      let(:year) { EdtfDateService.new("1863") }
      let(:month) { EdtfDateService.new("1863-11") }
      let(:day) { EdtfDateService.new("1863-11-21") }

      it 'responds to #humanize with the correct human-readable string' do
        expect(year.humanized).to eq "1863"
        expect(month.humanized).to eq "November 1863"
        expect(day.humanized).to eq "November 21, 1863"
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect([year.year_range, month.year_range, day.year_range]).to all(eq([1863]))
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect(year.solr_date_range).to eq(["1863-01-01T00:00:00Z"])
        expect(month.solr_date_range).to eq(["1863-11-01T00:00:00Z"])
        expect(day.solr_date_range).to eq(["1863-11-21T00:00:00Z"])
      end
    end

    context 'and date is before 1000' do

      let(:year) { EdtfDateService.new("900") }
      let(:month) { EdtfDateService.new("900-03") }
      let(:day) { EdtfDateService.new("900-06-01") }

      it 'responds to #humanize with the correct human-readable string' do
        expect(year.humanized).to eq("900")
        expect(month.humanized).to eq("March 900")
        expect(day.humanized).to eq("June 1, 900")
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect([year.year_range, month.year_range, day.year_range]).to all( eq([900]) )
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect(year.solr_date_range).to eq(["0900-01-01T00:00:00Z"])
        expect(month.solr_date_range).to eq(["0900-03-01T00:00:00Z"])
        expect(day.solr_date_range).to eq(["0900-06-01T00:00:00Z"])
      end
    end

  end

  context 'when date is a season' do

    let(:season) { EdtfDateService.new("2011-22") }

    it 'responds to #humanize with the correct human-readable string' do
      expect(season.humanized).to eq "Summer, 2011"
    end

    it 'responds to #year_range with the correct array of years (integers)' do
      expect(season.year_range).to eq([2011])
    end

    it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
      expect(season.solr_date_range).to start_with("2011-06-01T00:00:00Z") && end_with("2011-08-31T00:00:00Z")
    end

  end

  context 'when date is unspecified, a century, or a decade' do

    context 'and is after 1000' do
      let(:century) { EdtfDateService.new("19XX") }
      let(:decade) { EdtfDateService.new("192X")  }
      let(:lowercase_century) { EdtfDateService.new("19xx") }
      let(:lowercase_decade) { EdtfDateService.new("192x") }

      it 'responds to #humanize with the correct human-readable string' do
        expect(century.humanized).to eq(lowercase_century.humanized) & eq("1900s")
        expect(decade.humanized).to eq(lowercase_decade.humanized) & eq("1920s")
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect(century.year_range).to eq(lowercase_century.year_range) &
                                          start_with(1900) & end_with(1999)
        expect(decade.year_range).to eq(lowercase_decade.year_range) &
                                         start_with(1920) & end_with(1929)
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect(century.solr_date_range).to eq(lowercase_century.solr_date_range) &
                                               start_with("1900-01-01T00:00:00Z") &
                                               end_with("1999-01-01T00:00:00Z")
        expect(decade.solr_date_range).to eq(lowercase_decade.solr_date_range) &
                                              start_with("1920-01-01T00:00:00Z") &
                                              end_with("1929-01-01T00:00:00Z")
      end
    end

    context 'and date is before 1000' do
      let(:century) { EdtfDateService.new("9XX") }
      let(:decade) { EdtfDateService.new("97X") }

      it 'responds to #humanize with the correct human-readable string' do
        expect(century.humanized).to eq('900s')
        expect(decade.humanized).to eq('970s')
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect(century.year_range).to start_with(900) & end_with(999)
        expect(decade.year_range).to start_with(970) & end_with(979)
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect(century.solr_date_range).to start_with(["0900-01-01T00:00:00Z"]) & end_with(["0999-01-01T00:00:00Z"])
        expect(decade.solr_date_range).to start_with(["0970-01-01T00:00:00Z"]) & end_with(["0979-01-01T00:00:00Z"])
      end

    end

  end

  context 'when date is an interval' do

    let(:service) { EdtfDateService.new(date_string) }

    context 'that is open-ended' do

      let(:open_start) { EdtfDateService.new("../1900") }
      let(:open_end) { EdtfDateService.new("1900/..") }
      let(:pre_1000_start) { EdtfDateService.new("950/..") }
      let(:pre_1000_end) { EdtfDateService.new("../800") }

      it 'responds to #humanize with the correct human-readable string' do
        expect(open_start.humanized).to eq("Before 1900")
        expect(open_end.humanized).to eq("Post 1900")
        expect(pre_1000_start.humanized).to eq("Post 950")
        expect(pre_1000_end.humanized).to eq("Before 800")
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect(open_start.year_range).to eq(open_end.year_range) & eq([1900])
        expect(pre_1000_start.year_range).to eq([950])
        expect(pre_1000_end.year_range).to eq([800])
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect(open_start.solr_date_range).to eq(open_end.solr_date_range) & eq(["1900-01-01T00:00:00Z"])
        expect(pre_1000_start.solr_date_range).to eq(["0950-01-01T00:00:00Z"])
        expect(pre_1000_end.solr_date_range).to eq(["0800-01-01T00:00:00Z"])
      end

    end

    context 'of dates, both after 1000 AD' do

      let(:date_string) { "1989-11-09/1990-01-07" }

      it 'responds to #humanize with the correct human-readable string' do
        expect(service.humanized).to eq("November 9, 1989 to January 7, 1990")
      end

      it 'responds to #year_range with an array of years (integers)' do
        expect(service.year_range).to eq([1989, 1990])
      end

      it 'responds to #solr_date_range with an array of solr-formatted datetime strings' do
        expect(service.solr_date_range).to start_with("1989-11-09T00:00:00Z") & end_with("1990-01-07T00:00:00Z")
      end

    end

    context 'of seasons' do

      let(:date_string) { "2011-22/2011-24" }

      it 'responds to #humanize with the correct human-readable string' do
        expect(service.humanized).to eq("Summer, 2011 to Winter, 2011")
      end

      it 'responds to #year_range with an array of years (integers)' do
        expect(service.year_range).to eq([2011, 2012])
      end

      it 'responds to #solr_date_range with an array of solr-formatted datetime strings' do
        expect(service.solr_date_range).to start_with("2011-06-01T00:00:00Z") & end_with("2012-02-29T00:00:00Z")
      end

    end

    context 'of approximate (~), uncertain (?), or approximate and uncertain (%) dates' do

      let(:approx) { EdtfDateService.new("1965-10~/1975-11~") }
      let(:uncertain) { EdtfDateService.new("1965-10?/1970-10?") }
      let(:approx_and_uncertain) { EdtfDateService.new("1965-10%/1975-11%") }

      it 'responds to #humanize with the correct human-readable string' do
        expect(approx.humanized).to eq("approximately October 1965 to approximately November 1975")
        expect(uncertain.humanized).to eq("October 1965? to October 1970?")
        expect(approx_and_uncertain.humanized).to eq("approximately October 1965? to approximately November 1975?")
      end

      it 'responds to #year_range with an array of years (integers)' do
        expect(approx.year_range).to eq(approx_and_uncertain.year_range) & eq([*1965..1975])
        expect(uncertain.year_range).to eq([1965, 1966, 1967, 1968, 1969, 1970])
      end

      it 'responds to #solr_date_range with an array of solr-formatted datetime strings' do
        expect(approx.solr_date_range).to eq(approx_and_uncertain.solr_date_range) & start_with("1965-10-01T00:00:00Z") & end_with("1975-11-01T00:00:00Z")
        expect(uncertain.solr_date_range).to start_with("1965-10-01T00:00:00Z") & end_with("1970-10-01T00:00:00Z")
      end

    end

    context 'of centuries or decades' do

      let(:century) { EdtfDateService.new("14XX/15XX") }
      let(:decade) { EdtfDateService.new("198X/199X") }

      it 'responds to #humanize with the correct human-readable string' do
        expect(century.humanized).to eq("1400s to 1500s")
        expect(decade.humanized).to eq("1980s to 1990s")
      end

      it 'responds to #year_range with an array of years (integers)' do
        expect(century.year_range).to eq([*1400..1599])
        expect(decade.year_range).to eq([*1980..1999])
      end

      it 'responds to #solr_date_range with an array of solr-formatted datetime strings' do
        expect(century.solr_date_range).to start_with("1400-01-01T00:00:00Z") & end_with("1599-01-01T00:00:00Z")
        expect(decade.solr_date_range).to start_with("1980-01-01T00:00:00Z") & end_with("1999-01-01T00:00:00Z")
      end

    end

    context 'including date(s) before 1000' do

      let(:interval) { EdtfDateService.new("950/1000") }
      let(:interval_before_1000) { EdtfDateService.new("950/970") }

      it 'responds to #humanize with the correct human-readable string' do
        expect(interval.humanized).to eq('950 to 1000')
        expect(interval_before_1000.humanized).to eq('950 to 970')
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect(interval.year_range).to start_with(950) & end_with(1000)
        expect(interval_before_1000.year_range).to start_with(950) & end_with(970)
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect(interval.solr_date_range).to start_with(["0950-01-01T00:00:00Z"]) & end_with(["1000-01-01T00:00:00Z"])
        expect(interval_before_1000.solr_date_range).to start_with(["0950-01-01T00:00:00Z"]) & end_with(["0970-01-01T00:00:00Z"])
      end

    end

  end

  context 'when date is questionable and/or approximate' do

    let(:approx_service) { EdtfDateService.new(approx) }
    let(:uncertain_service) { EdtfDateService.new(uncertain) }
    let(:approx_and_uncertain_service) { EdtfDateService.new(approx_and_uncertain) }

    context 'and has year-specificity' do

      let(:approx) { "1965~" }
      let(:uncertain) { "1965?" }
      let(:approx_and_uncertain) { "1965%" }

      it 'responds to #humanize with the correct human-readable string' do
        expect(approx_service.humanized).to eq("approximately 1965")
        expect(uncertain_service.humanized).to eq("1965?")
        expect(approx_and_uncertain_service.humanized).to eq("approximately 1965?")
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect([approx_service.year_range, uncertain_service.year_range, approx_and_uncertain_service.year_range]).to all(eq([1965]))
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect([approx_service.solr_date_range, uncertain_service.solr_date_range, approx_and_uncertain_service.solr_date_range]).to all(eq(["1965-01-01T00:00:00Z"]))
      end
    end

    context 'and has month-specificity' do

      let(:approx) { "1975-10~" }
      let(:uncertain) { "1975-10?" }
      let(:approx_and_uncertain) { "1975-10%" }

      it 'responds to #humanize with the correct human-readable string' do
        expect(approx_service.humanized).to eq("approximately October 1975")
        expect(uncertain_service.humanized).to eq("October 1975?")
        expect(approx_and_uncertain_service.humanized).to eq("approximately October 1975?")
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect([approx_service.year_range, uncertain_service.year_range, approx_and_uncertain_service.year_range]).to all(eq([1975]))
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect([approx_service.solr_date_range, uncertain_service.solr_date_range, approx_and_uncertain_service.solr_date_range]).to all(eq(["1975-10-01T00:00:00Z"]))
      end
    end

    context 'and has day-specificity' do

      let(:approx) { "1985-10-05~" }
      let(:uncertain) { "1985-10-05?" }
      let(:approx_and_uncertain) { "1985-10-05%" }

      it 'responds to #humanize with the correct human-readable string' do
        expect(approx_service.humanized).to eq("approximately October 5, 1985")
        expect(uncertain_service.humanized).to eq("October 5, 1985?")
        expect(approx_and_uncertain_service.humanized).to eq("approximately October 5, 1985?")
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect([approx_service.year_range, uncertain_service.year_range, approx_and_uncertain_service.year_range]).to all(eq([1985]))
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect([approx_service.solr_date_range, uncertain_service.solr_date_range, approx_and_uncertain_service.solr_date_range]).to all(eq(["1985-10-05T00:00:00Z"]))
      end
    end

    context 'and is before 1000' do

      let(:approx) { "905-06-01~" }
      let(:uncertain) { "905-06-01?" }
      let(:approx_and_uncertain) { "905-06-01%" }

      it 'responds to #humanize with the correct human-readable string' do
        expect(approx_service.humanized).to eq("approximately June 1, 905")
        expect(uncertain_service.humanized).to eq("June 1, 905?")
        expect(approx_and_uncertain_service.humanized).to eq("approximately June 1, 905?")
      end

      it 'responds to #year_range with the correct array of years (integers)' do
        expect([approx_service.year_range, uncertain_service.year_range, approx_and_uncertain_service.year_range]).to all(eq([905]))
      end

      it 'responds to #solr_date_range with the correct array of solr-formatted datetime strings' do
        expect([approx_service.solr_date_range, uncertain_service.solr_date_range, approx_and_uncertain_service.solr_date_range]).to all(eq(["0905-06-01T00:00:00Z"]))
      end

    end

  end

  context 'when date is invalid or contains #' do

    it 'raises an invalid date error' do
      expect { EdtfDateService.new("invalid") }.to raise_error(EdtfDateService::InvalidEdtfDateError, 'Could not parse date: "invalid." If date is unknown, use "unknown" or "no date"')
    end

    it 'raises a specific error message for #' do
      expect { EdtfDateService.new("1989#") }.to raise_error(EdtfDateService::InvalidEdtfDateError, 'Could not parse date: "1989#." Date includes #, please use X or another alternative.')
    end

  end
end