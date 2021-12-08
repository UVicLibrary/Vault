RSpec.describe EdtfDateService do

  context 'when single date with year-, month-, or day-specificity' do

    let(:year) { EdtfDateService.new("1863") }
    let(:month) { EdtfDateService.new("1863-11") }
    let(:day) { EdtfDateService.new("1863-11-21") }

    it 'responds to #humanize with human-readable string' do
      expect(year.humanized).to eq "1863"
      expect(month.humanized).to eq "November 1863"
      expect(day.humanized).to eq "November 21, 1863"
    end

    it 'responds to #year_range with an array of years (integers)' do
      expect(year.year_range).to eq([1863])
      expect(month.year_range).to eq([1863])
      expect(day.year_range).to eq([1863])
    end

    it 'responds to #solr_date_range with an array of solr-formatted datetime strings' do
      expect(year.solr_date_range).to eq(["1863-01-01T00:00:00Z"])
      expect(month.solr_date_range).to eq(["1863-11-01T00:00:00Z"])
      expect(day.solr_date_range).to eq(["1863-11-21T00:00:00Z"])
    end

    it 'responds to #first_solr_date with the first possible (solr-formatted) date' do
      expect(year.first_solr_date).to eq("1863-01-01T00:00:00Z")
      expect(month.first_solr_date).to eq("1863-11-01T00:00:00Z")
      expect(day.first_solr_date).to eq("1863-11-21T00:00:00Z")
    end

  end

  context 'when date is a season' do

    let(:season) { EdtfDateService.new("2011-22") }

    it 'responds to #humanize with human-readable string' do
      expect(season.humanized).to eq "Summer, 2011"
    end

    it 'responds to #year_range with an array of years (integers)' do
      expect(season.year_range).to eq([2011])
    end

    it 'responds to #solr_date_range with an array of solr-formatted datetime strings' do
      expect(season.solr_date_range).to start_with("2011-06-01T00:00:00Z") && end_with("2011-08-31T00:00:00Z")
    end

    it 'responds to #first_solr_date with the first possible (solr-formatted) date' do
      expect(season.first_solr_date).to eq "2011-06-01T00:00:00Z"
    end

  end

  context 'when date is an interval' do

    let(:intervals) {
      hash = { "year" => "1920/1929",
        "date" => "1989-11-09/1990-01-07",
        "season" => "2011-22/2011-24",
        "uncertain" => "1965-10?/1970-10?",
        "approximate" => "1965-10~/1975-11~",
        "approx_and_uncertain" => "1965-10%/1975-11%" }
      hash.transform_values { |val| EdtfDateService.new(val) }
    }

    it 'responds to #humanize with human-readable string' do
      expect(intervals.transform_values(&:humanized)).to eq({
         "year" => "1920 to 1929",
         "date" => "November 9, 1989 to January 7, 1990",
         "season" => "Summer, 2011 to Winter, 2011",
         "uncertain" => "October 1965? to October 1970?",
         "approximate" => "approximately October 1965 to approximately November 1975",
         "approx_and_uncertain" => "approximately October 1965? to approximately November 1975?"
         })
    end

    it 'responds to #year_range with an array of years (integers)' do
      expect(intervals.transform_values(&:year_range)).to eq({
        "year" => [*1920..1929],
        "date" => [1989, 1990],
        "season" => [2011, 2012],
        "uncertain" => [1965, 1966, 1967, 1968, 1969, 1970],
        "approximate" => [*1965..1975],
        "approx_and_uncertain" => [*1965..1975]
      })
    end

    it 'responds to #solr_date_range with an array of solr-formatted datetime strings' do
      transformed = intervals.transform_values(&:solr_date_range)
        expect(transformed['year']).to start_with("1920-01-01T00:00:00Z") & end_with("1929-01-01T00:00:00Z")
        expect(transformed['date']).to start_with("1989-11-09T00:00:00Z") & end_with("1990-01-07T00:00:00Z")
        expect(transformed['season']).to start_with("2011-06-01T00:00:00Z") & end_with("2012-02-29T00:00:00Z")
        expect(transformed['uncertain']).to start_with("1965-10-01T00:00:00Z") & end_with("1970-10-01T00:00:00Z")
        expect(transformed['approximate']).to eq(transformed['approx_and_uncertain']) &
                                                  start_with("1965-10-01T00:00:00Z") &
                                                  end_with("1975-11-01T00:00:00Z")
      # end
    end

    it 'responds to #first_solr_date with the first possible (solr-formatted) date' do
      expect(intervals.transform_values(&:first_solr_date)).to eq({
        "year" => "1920-01-01T00:00:00Z",
        "date" => "1989-11-09T00:00:00Z",
        "season" => "2011-06-01T00:00:00Z",
        "uncertain" => "1965-10-01T00:00:00Z",
        "approximate" => "1965-10-01T00:00:00Z",
        "approx_and_uncertain" => "1965-10-01T00:00:00Z"
      })
    end

  end

  context 'when date is unspecified' do

    let(:century) { EdtfDateService.new("19XX") }
    let(:decade) { EdtfDateService.new("192X")  }
    let(:lowercase_century) { EdtfDateService.new("19xx") }
    let(:lowercase_decade) { EdtfDateService.new("192x") }

    it 'responds to #humanize with human-readable string' do
      expect(century.humanized).to eq(lowercase_century.humanized) & eq("1900s")
      expect(decade.humanized).to eq(lowercase_decade.humanized) & eq("1920s")
    end

    it 'responds to #year_range with an array of years (integers)' do
      expect(century.year_range).to eq(lowercase_century.year_range) &
                                      start_with(1900) & end_with(1999)
      expect(decade.year_range).to eq(lowercase_decade.year_range) &
                                      start_with(1920) & end_with(1929)
    end

    it 'responds to #solr_date_range with an array of solr-formatted datetime strings' do
      expect(century.solr_date_range).to eq(lowercase_century.solr_date_range) &
                                             start_with("1900-01-01T00:00:00Z") &
                                             end_with("1999-01-01T00:00:00Z")
      expect(decade.solr_date_range).to eq(lowercase_decade.solr_date_range) &
                                            start_with("1920-01-01T00:00:00Z") &
                                            end_with("1929-01-01T00:00:00Z")
    end

    it 'responds to #first_solr_date with the first possible (solr-formatted) date' do
      expect(century.first_solr_date).to eq(lowercase_century.first_solr_date) &
                                         eq("1900-01-01T00:00:00Z")
      expect(decade.first_solr_date).to eq(lowercase_decade.first_solr_date) &
                                        eq("1920-01-01T00:00:00Z")
    end

  end

  context 'when date is questionable and/or approximate' do

    # Initialize a service for questionable, approx, and q/a dates
    let(:year) { [ EdtfDateService.new("1965?"),
                   EdtfDateService.new("1965~"),
                   EdtfDateService.new("1965%")] }

    let(:month) { [EdtfDateService.new("1975-10?"),
                   EdtfDateService.new("1975-10~"),
                   EdtfDateService.new("1975-10%")] }

    let(:day) { [EdtfDateService.new("1985-10-05?"),
                 EdtfDateService.new("1985-10-05~"),
                 EdtfDateService.new("1985-10-05%")] }

    it 'responds to #humanize with human-readable string' do
      expect(year.first.humanized).to eq("1965?") # Questionable
      expect(year.second.humanized).to eq("approximately 1965") # Approximate
      expect(year.third.humanized).to eq("approximately 1965?") # Questionable and Approximate

      expect(month.first.humanized).to eq("October 1975?") # Questionable
      expect(month.second.humanized).to eq("approximately October 1975") # Approximate
      expect(month.third.humanized).to eq("approximately October 1975?") # Questionable and Approximate

      expect(day.first.humanized).to eq("October 5, 1985?") # Questionable
      expect(day.second.humanized).to eq("approximately October 5, 1985") # Approximate
      expect(day.third.humanized).to eq("approximately October 5, 1985?") # Questionable and Approximate
    end

    it 'responds to #year_range with an array of years (integers)' do
      expect(year.map(&:year_range)).to all(eq([1965])) # Questionable
      expect(month.map(&:year_range)).to all(eq([1975])) # Approximate
      expect(day.map(&:year_range)).to all(eq([1985])) # Questionable and Approximate
    end

    it 'responds to #solr_date_range with an array of solr-formatted datetime strings' do
      expect(year.map(&:solr_date_range)).to all(eq(["1965-01-01T00:00:00Z"])) # Questionable
      expect(month.map(&:solr_date_range)).to all(eq(["1975-10-01T00:00:00Z"])) # Approximate
      expect(day.map(&:solr_date_range)).to all(eq(["1985-10-05T00:00:00Z"])) # Questionable and Approximate
    end

    it 'responds to #first_solr_date with the first possible (solr-formatted) date' do
      expect(year.map(&:first_solr_date)).to all(eq("1965-01-01T00:00:00Z")) # Questionable
      expect(month.map(&:first_solr_date)).to all(eq("1975-10-01T00:00:00Z")) # Approximate
      expect(day.map(&:first_solr_date)).to all(eq("1985-10-05T00:00:00Z")) # Questionable and Approximate
    end

  end

  context 'when date is invalid or contains #' do

    it 'raises an invalid date error' do
      expect { EdtfDateService.new("invalid") }.to raise_error(EdtfDateService::InvalidEdtfDateError, "Could not parse date: invalid. If date is unknown, use \"unknown\" or \"no date\"")
    end

    it 'raises a specific error message for #' do
      expect { EdtfDateService.new("1989#") }.to raise_error(EdtfDateService::InvalidEdtfDateError, "Could not parse date: 1989#. Date includes #.")
    end

  end
end