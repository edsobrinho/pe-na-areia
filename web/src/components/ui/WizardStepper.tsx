export interface WizardStepItem {
  id: string
  number: number
  title: string
  subtitle: string
  icon: string
  completed?: boolean
}

interface WizardStepperProps {
  steps: WizardStepItem[]
  activeStepId: string
  onSelectStep?: (stepId: string) => void
}

export function WizardStepper({ steps, activeStepId, onSelectStep }: WizardStepperProps) {
  const activeIndex = Math.max(
    0,
    steps.findIndex((s) => s.id === activeStepId),
  )

  return (
    <nav className="wizard-stepper" aria-label="Etapas do Cadastro e Configuração do Parceiro">
      <div className="wizard-track">
        {steps.map((step, index) => {
          const isActive = step.id === activeStepId
          const isPast = index < activeIndex
          const isDone = Boolean(step.completed || isPast)
          const stateClass = isActive ? 'active' : isDone ? 'completed' : 'upcoming'

          return (
            <button
              key={step.id}
              type="button"
              className={`wizard-step ${stateClass}`}
              onClick={() => onSelectStep?.(step.id)}
              disabled={!onSelectStep}
              aria-current={isActive ? 'step' : undefined}
            >
              <span className="wizard-step-badge" aria-hidden="true">
                {isDone && !isActive ? '✓' : step.number}
              </span>
              <span className="wizard-step-text">
                <strong>
                  {step.icon} {step.title}
                </strong>
                <small>{step.subtitle}</small>
              </span>
            </button>
          )
        })}
      </div>
    </nav>
  )
}

