'use client'

export function TableSkeleton() {
  return (
    <div className="space-y-4">
      {[...Array(5)].map((_, i) => (
        <div key={i} className="card-stitch space-y-3">
          <div className="h-4 bg-surface-high rounded-lg w-3/4 animate-pulse" />
          <div className="flex gap-4">
            <div className="h-4 bg-surface-high rounded-lg w-1/4 animate-pulse" />
            <div className="h-4 bg-surface-high rounded-lg w-1/4 animate-pulse" />
            <div className="h-4 bg-surface-high rounded-lg w-1/4 animate-pulse" />
          </div>
        </div>
      ))}
    </div>
  )
}

export function FormSkeleton() {
  return (
    <div className="space-y-6">
      {[...Array(4)].map((_, i) => (
        <div key={i} className="space-y-2">
          <div className="h-4 bg-surface-high rounded-lg w-1/4 animate-pulse" />
          <div className="h-10 bg-surface-container rounded-lg animate-pulse" />
        </div>
      ))}
      <div className="h-12 bg-gradient-to-br from-[#2563eb] to-[#571bc1] rounded-xl animate-pulse" />
    </div>
  )
}

export function DashboardSkeleton() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {[...Array(4)].map((_, i) => (
          <div key={i} className="card-stitch h-24 animate-pulse" />
        ))}
      </div>
      <div className="card-stitch h-64 animate-pulse" />
    </div>
  )
}
