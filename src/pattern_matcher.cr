require "./patterns/*"

module HM
  class PatternMatcher
    getter environment : Environment

    def initialize(@environment)
    end

    # Matches a number patterns against the patterns of the branches of the type
    # (useful for case like expressions). Once a pattern is matched we stop
    # matching it.
    #
    # It returnes a hash with useful information:
    # - not_covered - branches that are not covered by any of the patterns
    # - not_matched - patterns that are not matched to any of the branches
    # - covered - branches that are covered by a pattern
    # - matched - patterns that are covered by a branch
    #
    # If it returns nil that means that the type is not sound.
    def match_patterns(patterns : ::Array(Pattern), type : Checkable)
      return nil unless environment.sound?(type)

      branches =
        HM::BranchEnumerator
          .new(environment)
          .possibilities(type)
          .flat_map { |branch| PatternGenerator.generate(branch) }
          .to_set

      covered = Set(Pattern).new
      matched = Set(Pattern).new

      branches.each do |branch|
        patterns.each do |pattern|
          next if covered.includes?(branch) &&
                  matched.includes?(pattern)

          if pattern.matches?(branch) || branch.matches?(pattern)
            pattern.copy_type_from(branch)
            covered.add(branch)
            matched.add(pattern)
          end
        end
      end

      {
        not_matched: patterns.to_set - matched,
        not_covered: branches - covered,
        covered:     covered,
        matched:     matched,
      }
    end

    # # Matches a number patterns against the branches of the type (useful
    # # for case like expressions). Once a pattern is matched we stop matching it.
    # #
    # # It returnes a hash with useful information:
    # # - not_covered - branches that are not covered by any of the patterns
    # # - not_matched - patterns that are not matched to any of the branches
    # # - covered - branches that are covered by a pattern
    # # - matched - patterns that are covered by a branch
    # #
    # # If it returns nil that means that the type is not sound.
    # def match(patterns : ::Array(Pattern), type : Checkable)
    #   return nil unless environment.sound?(type)

    #   branches =
    #     HM::BranchEnumerator
    #       .new(environment)
    #       .possibilities(type)
    #       .to_set

    #   covered = Set(Checkable).new
    #   matched = [] of Pattern

    #   branches.each do |branch|
    #     patterns.each do |pattern|
    #       next if covered.includes?(pattern)

    #       if pattern.matches?(branch)
    #         covered.add(branch)
    #         matched << pattern
    #       end
    #     end
    #   end

    #   {
    #     not_covered: branches - covered,
    #     not_matched: patterns - matched,
    #     covered:     covered,
    #     matched:     matched,
    #   }
    # end
  end
end
