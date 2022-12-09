require "./hm_type_system"
require "kemal"

get "/" do
  render "src/playground/index.ecr", "src/playground/layout.ecr"
end

get "/unifier" do |env|
  type1 = env.params.query["type1"]? || ""
  type2 = env.params.query["type2"]? || ""

  result =
    if type1.blank? && type2.blank?
      ""
    else
      begin
        parsed1 =
          HM::Parser.type(type1)

        parsed2 =
          HM::Parser.type(type2)

        if parsed1
          if parsed2
            unified =
              HM::Unifier.unify(parsed1, parsed2)

            if unified
              HM::Formatter.format(unified)
            else
              "Couldn't unify!"
            end
          else
            "Couldn't parse type2"
          end
        else
          "Couldn't parse type1"
        end
      end
    end

  render "src/playground/unifier.ecr", "src/playground/layout.ecr"
end

get "/branch-enumerator" do |env|
  types = env.params.query["types"]? || ""
  type = env.params.query["type"]? || ""

  result =
    if types.blank? || type.blank?
      ""
    else
      definitions =
        HM::Parser.definitions(types)

      parsed =
        HM::Parser.type(type)

      if definitions
        if parsed
          environment =
            HM::Environment.new(definitions)

          if environment.sound?
            if environment.sound?(parsed)
              HM::BranchEnumerator
                .new(environment)
                .possibilities(parsed)
                .map { |branch| HM::Formatter.format(branch) }
                .join("\n")
            else
              "Type is not sound!"
            end
          else
            "Types are not sound!"
          end
        else
          "Couldn't parse type"
        end
      else
        "Couldn't parse types"
      end
    end

  render "src/playground/branch_enumerator.ecr", "src/playground/layout.ecr"
end

Kemal.run
